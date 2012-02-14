# -*- coding: utf-8 -*-
#
# Rakefile tasks for Ruby-Elf
# Copyright © 2011 Diego Elio Pettenò <flameeyes@flameeyes.eu>
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
  def git_tagged?
    unless File.exists?(".git")
      raise Exception.new("Can't execute this task outside of Ruby-Elf git repository")
    end

    # we use read.split because lines will include the final \n and it's
    # a bother; we also skip over .gitignore since we never want to
    # package that.
    IO.popen("git tag -l ruby-elf-#{Elf::VERSION}").read == "ruby-elf-#{Elf::VERSION}\n"
  end

  desc "Tag and publish the release"
  task :release => :package do
    if git_tagged?
      $stderr.puts "The current release is already tagged; did you forget to bump the version?"
      exit 1
    end

    sh "git", "tag", "-m", "Release #{Elf::VERSION}", "ruby-elf-#{Elf::VERSION}"
    sh "gem", "push", "pkg/ruby-elf-#{Elf::VERSION}.gem"
    sh "rubyforge", "add_release", "ruby-elf", "ruby-elf", Elf::VERSION, "pkg/ruby-elf-#{Elf::VERSION}.tar.bz2"
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
