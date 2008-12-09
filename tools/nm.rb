#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Copyright © 2007, Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

# bsd-nm implementation based on elf.rb (very limited)

require 'elf'
require 'getoptlong'

opts = GetoptLong.new(
  ["--dynamic", "-D", GetoptLong::NO_ARGUMENT]
)

scan_section = '.symtab'

opts.each do |opt, arg|
  case opt
  when '--dynamic'
    scan_section = '.dynsym'
  end
end

exitval = 0

files = ARGV.length > 0 ? ARGV : ['a.out']

files.each do |file|
  begin
    Elf::File.open(file) do |elf|
      addrsize = (elf.elf_class == Elf::Class::Elf32 ? 8 : 16)

      if not elf.has_section? scan_section
        $stderr.puts "nm.rb: #{elf.path}: No symbols"
        exitval = 1
        next
      end

      elf[scan_section].each_symbol do |sym|
        next if sym.name == ''

        addr = sprintf("%0#{addrsize}x", sym.value)

        addr = ' ' * addrsize unless sym.section

        begin
          flag = sym.nm_code
        rescue Elf::Symbol::UnknownNMCode => e
          $stderr.puts e.message
          flag = "?"
        end

        version_name = sym.version
        version_name = version_name ? "@@#{version_name}" : ""

        puts "#{addr} #{flag} #{sym.name}#{version_name}"
      end
    end
  rescue Errno::ENOENT
    $stderr.puts "nm.rb: #{file}: No such file"
  end
end

exit exitval
