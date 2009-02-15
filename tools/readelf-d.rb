#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Copyright © 2007-2009 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

# readelf -d implementation based on elf.rb (very limited)

require 'elf'
require 'getoptlong'

files = ARGV.length > 0 ? ARGV : ['a.out']

files.each do |file|
  puts
  begin
    Elf::File.open(file) do |elf|
      dynsection = elf['.dynamic']

      unless dynsection
        puts "There is no dynamic section in this file."
        next
      end
      
      addrsize = (elf.elf_class == Elf::Class::Elf32 ? 8 : 16)

      puts "Dynamic section at offset 0x#{dynsection.offset.hex} contains #{dynsection.size} entries"
      puts "  Tag        Type                         Name/Value"

      dynsection.each_entry do |entry|

        case entry.type
        when Elf::Dynamic::Type::Needed
          val = "Shared library: [#{entry.parsed}]"
        when Elf::Dynamic::Type::Auxiliary
          val = "Auxiliary library: [#{entry.parsed}]"
        when Elf::Dynamic::Type::SoName
          val = "Library soname: [#{entry.parsed}]"
        when Elf::Dynamic::Type::StrSz, Elf::Dynamic::Type::SymEnt,
          Elf::Dynamic::Type::PltRelSz, Elf::Dynamic::Type::RelASz,
          Elf::Dynamic::Type::RelAEnt

          val = "#{entry.value} (bytes)"
        when Elf::Dynamic::Type::VerDefNum, Elf::Dynamic::Type::VerNeedNum, Elf::Dynamic::Type::RelACount
          val = entry.value
        when Elf::Dynamic::Type::GNUPrelinked
          val = entry.parsed.getutc.strftime('%Y-%m-%dT%H:%M:%S')
        else
          val = sprintf "0x%0#{addrsize}x", entry.value
        end

        printf " 0x%08x %-28s %s\n", entry.type.to_i, "(#{entry.type.to_s})", val

        break if entry.type == Elf::Dynamic::Type::Null
      end
    end
  rescue Errno::ENOENT
    $stderr.puts "readelf-d.rb: '#{file}': No such file"
    exit 1
  end
end

exit 0

