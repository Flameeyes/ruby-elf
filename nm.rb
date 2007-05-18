#!/usr/bin/env ruby
# Copyright © 2007, Diego "Flameeyes" Pettenò <flameeyes@gmail.com>
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

      symsection = elf.sections[scan_section]

      if symsection == nil
        $stderr.puts "nm.rb: #{elf.path}: No symbols"
        exitval = 1
        next
      end

      symsection.symbols.each do |sym|
        next if sym.name == ''

        addr = sprintf("%0#{addrsize}x", sym.value)

        addr = ' ' * addrsize unless sym.section

        versioned = elf.sections['.gnu.version'] != nil
        flag = '?'
        if sym.idx == 0
          next
        elsif sym.bind == Elf::Symbol::Binding::Weak
          flag = sym.type == Elf::Symbol::Type::Object ? 'V' : 'W'
          
          flag.downcase! if sym.value == 0
          # The following are three 'reserved sections'
        elsif sym.section == Elf::Section::Undef
          flag = 'U'
        elsif sym.section == Elf::Section::Abs
          # Absolute symbols
          flag = 'A'
          versioned = false
        elsif sym.section == Elf::Section::Common
          # Common symbols
          flag = 'C'
        elsif sym.section.is_a? Integer
          $stderr.puts sym.section.hex
          flag = '!'
        elsif sym.section.name == '.init'
          next
        else
          flag = case sym.section.name
                 when ".bss" then 'B'
                 when /\.rodata.*/ then 'R'
                 when ".text" then 'T'
                 else '?'
                 end
        end

        versioned = false if sym.section.is_a? Elf::Section and sym.section.name == ".bss"

        flag.downcase! if sym.bind == Elf::Symbol::Binding::Local

        if versioned
          version_idx = elf.sections['.gnu.version'][sym.idx]
          if version_idx >= 2
            if sym.section == nil
              version_name = elf.sections['.gnu.version_r'][version_idx][:name]
            else
              if version_idx & (1 << 15) == 0
                version_name = elf.sections['.gnu.version_d'][version_idx][:names][0]
              else
                version_idx = version_idx & ~(1 << 15)
                version_name = elf.sections['.gnu.version_d'][version_idx][:names][1]
              end
            end

            version_name = "@@#{version_name}"
          end
        end

        puts "#{addr} #{flag} #{sym.name}#{version_name}"
      end
    end
  rescue Errno::ENOENT
    $stderr.puts "nm.rb: #{file}: No such file"
  end
end

exit exitval
