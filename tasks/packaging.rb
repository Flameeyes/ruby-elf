# -*- coding: utf-8 -*-
#
# Rakefile tasks for Ruby-Elf
# Copyright © 2011 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this generator; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

begin
  def git_files
    unless File.exists?(".git")
      raise Exception.new("Can't execute this task outside of Ruby-Elf git repository")
    end

    # we use read.split because lines will include the final \n and it's
    # a bother; we also skip over .gitignore since we never want to
    # package that.
    IO.popen("git ls-files").read.split(/\r?\n/).reject { |file| file == ".gitignore" }
  end

  Spec = Gem::Specification.new do |s|
    s.platform = Gem::Platform::RUBY
    s.summary = "Pure Ruby ELF file parser and utilities"
    s.name = "ruby-elf"
    s.version = Elf::VERSION
    s.requirements << 'none'
    s.require_path = 'lib'
    s.rubyforge_project = "ruby-elf"
    s.homepage = "http://www.flameeyes.eu/projects/ruby-elf"
    s.license = "GPL-2 or later"
    s.author = "Diego Elio Pettenò"
    s.email = "flameeyes@gmail.com"

    s.files = git_files.reject { |file|
      file =~ /(^Rakefile$|^(test|tasks)\/|\.(xmli|rl)?$)/
    }
    s.files |= DemanglersList | ManpagesList

    s.executables = FileList["bin/*"].collect { |bin|
      next if bin =~ /~$/
      bin.sub(/^bin\//, '')
    }

    s.description = <<EOF
Ruby-Elf is a pure-Ruby library for parse and fetch information about
ELF format used by Linux, FreeBSD, Solaris and other Unix-like
operating systems, and include a set of analysis tools helpful for
both optimisations and verification of compiled ELF files.
EOF
  end

  file "ruby-elf-#{Elf::VERSION}.gemspec" => "Rakefile" do |t|
    File.new(t.name, "w").write Spec.to_ruby
  end

  require 'rake/packagetask'
  Rake::PackageTask.new("ruby-elf", Elf::VERSION) do |pkg|
    pkg.need_tar_bz2 = true
    pkg.package_dir = "pkg"
    pkg.package_files = git_files | DemanglersList | ManpagesList
    pkg.package_files << "ruby-elf-#{Elf::VERSION}.gemspec"
  end

  require 'rake/gempackagetask'
  Rake::GemPackageTask.new(Spec) do |pkg|
  end
rescue Exception => e
  # This can happen for instance if you're not running from within a
  # git checkout. In that case we ignore the whole file.
  raise unless e.message == "Can't execute this task outside of Ruby-Elf git repository"
end

# Local Variables:
# mode: ruby
# mode: flyspell-prog
# ispell-local-dictionary: "english"
# End:
