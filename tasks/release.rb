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

    IO.popen("git tag -l #{Elf::VERSION}").read == "#{Elf::VERSION}\n"
  end

  desc "Tag and publish the release"
  task :package => ManpagesList do
    if git_tagged?
      $stderr.puts "The current release is already tagged; did you forget to bump the version?"
      exit 1
    end

    sh "gem", "build", "ruby-elf.gemspec"
    sh "git", "tag", "-m", "Release #{Elf::VERSION}", "#{Elf::VERSION}"
    sh "gem", "push", "ruby-elf-#{Elf::VERSION}.gem"
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
