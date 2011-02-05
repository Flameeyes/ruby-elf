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

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "tests/tc_*.rb"
  t.libs = ["lib", "tests"]
end

task :test => :demanglers

begin
  require 'rcov/rcovtask'
  
  Rcov::RcovTask.new do |t|
    t.pattern = "tests/tc_*.rb"
    t.libs = ["lib", "tests"]
  end

  task :rcov => :demanglers
rescue LoadError
  $stderr.puts "Unable to find rcov, coverage won't be available"
end

# Local Variables:
# mode: ruby
# mode: flyspell-prog
# ispell-local-dictionary: "english"
# End:
