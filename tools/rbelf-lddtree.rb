#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Copyright © 2007-2010 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

# Proof of Concept tool to implement ldd-like dependency scan with
# dependency tree. It is similar to lddtree.sh script as provided by
# scanelf, but not the same thing.

require 'elf'
require 'elf/utils/loader'

require 'set'

$seen_libraries = Set.new

def print_dependency_list(elf, indent_level)
  elf[".dynamic"].needed_libraries.each_pair do |soname, lib|
    case
    when lib.nil?
      puts "#{"  "*indent_level}#{soname} => not found"
    when $seen_libraries.include?(lib.path)
      puts "#{"  "*indent_level}#{soname} => #{lib.path} +"
    else
      puts "#{"  "*indent_level}#{soname} => #{lib.path}"
      print_dependency_list(lib, indent_level+1)
      
      $seen_libraries |= lib.path
    end
  end
end

Elf::File.open(ARGV[0]) do |elf|
  puts ARGV[0]
  print_dependency_list(elf, 1)
end
