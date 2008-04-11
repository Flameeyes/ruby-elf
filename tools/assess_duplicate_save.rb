#!/usr/bin/env ruby
# Copyright © 2008, Diego "Flameeyes" Pettenò <flameeyes@gmail.com>
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

# Simple script to assess the amount of space saved by duplicate removal of
# entries in symbols' tables.

require 'elf'

file_list = nil

# If there are no arguments passed through the command line
# consider it like we're going to act on stdin.
if not file_list and ARGV.size == 0
  file_list = $stdin
end

def assess_save(file)
  begin
    Elf::File.open(file) do |elf|
      seenstr = Set.new

      [ ['.dynsym', '.dynstr'], ['.symtab', '.strtab'] ].each do
        |symbols_section, strings_section|

        symsec = elf.sections[symbols_section]
        strsec = elf.sections[strings_section]

        next unless symsec and strsec

        # The NULL-entry can be aliased on the last string anyway by
        # letting it point to sectionsize-1
        fullsize = 0

        symsec.symbols.each do |sym|
          next if seenstr.include? sym.name
          seenstr.add sym.name
          fullsize += sym.name.length+1
        end
        
        # Dynamic executables and shared objects keep more data into the
        # .dynstr than static executables, in particular they have symbols
        # versions, their soname and their NEEDED sections strings.
        if strings_section == ".dynstr"
          versec = elf.sections['.gnu.version_d']
          if versec
            versec.each do |veridx, ver|
              ver[:names].each do |vername|
                next if seenstr.include? vername
                seenstr.add vername
                fullsize += vername.length+1
              end
            end
          end

          versec = elf.sections['.gnu.version_r']
          if versec
            versec.each do |veridx, ver|
              next if seenstr.include? ver[:name]
              seenstr.add ver[:name]
              fullsize += ver[:name].length+1
            end
          end

          elf.sections['.dynamic'].entries.each do |entry|
            case entry[:type]
            when Elf::Dynamic::Type::Needed, Elf::Dynamic::Type::SoName
              next if seenstr.include? entry[:parsed]
              seenstr.add entry[:parsed]
              fullsize += entry[:parsed].length+1
            end
          end

        end

        puts "#{file}: current size #{strsec.size}, full size #{fullsize} difference #{fullsize-strsec.size}"
      end
    end
  rescue Errno::ENOENT
    $stderr.puts "assess_duplicate_save.rb: #{file}: no such file"
  rescue Errno::EISDIR
    $stderr.puts "assess_duplicate_save.rb: #{file}: is a directory"
  rescue Elf::File::NotAnELF
    $stderr.puts "assess_duplicate_save.rb: #{file}: not a valid ELF file."
  end
end

if file_list
  file_list.each_line do |file|
    assess_save(file.rstrip)
  end
else
  ARGV.each do |file|
    assess_save(file)
  end
end
