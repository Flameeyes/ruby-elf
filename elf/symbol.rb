# Simple ELF parser for Ruby
#
# Copyright 2007 Diego Pettenò <flameeyes@gmail.com>
# Portions inspired by elf.py
#   Copyright 2002 Netgraft Corporation
# Portions inspired by elf.h
#   Copyright 1995-2006 Free Software Foundation, Inc.
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

class Elf
  class Symbol
    class Binding < Value
      fill({
              0 => [ :Local, 'Local symbol' ],
              1 => [ :Global, 'Global symbol' ],
              2 => [ :Weak, 'Weak symbol' ],
             # This one is inferred out of libpam.so
              3 => [ :Number, 'Number of defined type' ],
             10 => [ :LoOs, 'OS-specific range start' ],
             12 => [ :HiOs, 'OS-specific range end' ],
             13 => [ :LoProc, 'Processor-specific range start' ],
             15 => [ :HiProc, 'Processor-specific range end' ]
           })
    end

    class Type < Value
      fill({
              0 => [ :None, 'Unspecified' ],
              1 => [ :Object, 'Data object' ],
              2 => [ :Func, 'Code object' ],
              3 => [ :Section, 'Associated with a section' ],
              4 => [ :File, 'File name' ],
              5 => [ :Common, 'Common data object' ],
              6 => [ :TLS, 'Thread-local data object' ],
             10 => [ :LoOs, 'OS-specific range start' ],
             12 => [ :HiOs, 'OS-specific range end' ],
             13 => [ :LoProc, 'Processor-specific range start' ],
             15 => [ :HiProc, 'Processor-specific range end' ]
           })
    end

    attr_reader :value, :size, :other, :bind, :type, :idx

    # Create a new Symbol object reading the symbol structure from the file.
    # This function assumes that the elf file is aligned ad the
    # start of a symbol structure, and returns the file moved at the
    # start of the symbol.
    def initialize(elf, symsect, idx)
      @symsect = symsect
      @idx = idx

      case elf.elf_class
      when Class::Elf32
        @name = elf.read_word
        @value = elf.read_addr
        @size = elf.read_word
        info = elf.read_u8
        @other = elf.read_u8
        @section = elf.read_section
      when Class::Elf64
        @name = elf.read_word
        info = elf.read_u8
        @other = elf.read_u8
        @section = elf.read_section
        @value = elf.read_addr
        @size = elf.read_xword
      end

      begin
        @bind = Binding[info >> 4]
        @type = Type[info & 0xF]
      rescue Elf::Value::OutOfBound => e
        e.append_message("While processing symbol #{@idx}. Symbol info: 0x#{info.hex}")
        raise e
      end

      @file = elf
    end

    def name
      # We didn't read the name in form of string yet;
      if @name.is_a? Integer and @symsect.link
        name = @symsect.link[@name]
        @name = name if name
      end

      @name
    end

    def section
      # We didn't read the section yet.
      @section = nil if @section == 0

      if @section.is_a? Integer and @file.sections[@section]
        @section = @file.sections[@section]
      end

      @section
    end

    def version
      return nil if @file.sections['.gnu.version'] == nil or
        section == Elf::Section::Abs or
        ( section.is_a? Elf::Section and section.name == ".bss" )

      version_idx = @file.sections['.gnu.version'][@idx]
      
      return nil unless version_idx && version_idx >= 2

      return @file.sections['.gnu.version_r'][version_idx][:name] if section == nil

      name_idx = (version_idx & (1 << 15) == 0) ? 0 : 1
      version_idx = version_idx & ~(1 << 15)
      
      return @file.sections['.gnu.version_d'][version_idx][:names][name_idx]
    end
  end
end
