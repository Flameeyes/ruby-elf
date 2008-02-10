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

require 'set'

module Elf
  class Section
    # Reserved sections' indexes
    Undef  = nil    # Would be '0', but this fits enough
    Abs    = 0xfff1 # Absolute symbols
    Common = 0xfff2 # Common symbols

    # Create a new Section object reading the section's header from
    # the file.
    # This function assumes that the elf file is aligned ad the
    # start of a section header, and returns the file moved at the
    # start of the next header.
    def Section.read(elf)
      name = elf.read_word
      type_id = elf.read_word
      
      if type_id >= Type::LoProc.val && type_id <= Type::HiProc.val
        case elf.machine
        when Elf::Machine::ARM
          type = Type::ProcARM[type_id]
        end
      # elsif type_id >= Type::LoOs.val && type_id <= Type::HiOs.val
      else
        type = Type[type_id]
      end

      if Type::Class[type]
        return Type::Class[type].new(elf, name, type)
      else
        return Section.new(elf, name, type)
      end
    end

    attr_reader :offset, :type

    def initialize(elf, name, type)
      elf32 = elf.elf_class == Class::Elf32

      @file = elf
      @name = name
      @type = type
      @flags_val = elf32 ? elf.read_word : elf.read_xword
      @addr = elf.read_addr
      @offset = elf.read_off
      @size = elf32 ? elf.read_word : elf.read_xword
      @link = elf.read_word
      @info = elf.read_word
      @addralign = elf32 ? elf.read_word : elf.read_xword
      @entsize = elf32 ? elf.read_word : elf.read_xword

      @numentries = @size/@entsize unless @entsize == 0
    end

    def name
      # We didn't read the name in form of string yet;
      # Check if the file has loaded a string table yet
      if @name.is_a? Integer and @file.string_table
        @name = @file.string_table[@name]
      end

      @name
    end

    # Alias to_s to name so that using this in a string will report the name
    alias :to_s :name

    def link
      # We didn't get the linked section header yet
      if @link.is_a? Integer
        @link = @file.sections[@link]
      end

      @link
    end

    # Return a set of flag items, easier to check for single elements.
    def flags
      return @flags if @flags
      
      @flags = Set.new
      Flags.each do |flag|
        flags.add(flag) if (@flags_val & flag.val) == flag.val
      end

      @flags
    end

    def load
      oldpos = @file.tell
      @file.seek(@offset, IO::SEEK_SET)

      load_internal

      @file.seek(oldpos, IO::SEEK_SET)
    end

    def summary
      $stdout.puts "#{name}\t\t#{@type}\t#{@flags_val}\t#{@addr}\t#{@offset}\t#{@size}\t#{@link}\t#{@info}\t#{@addralign}\t#{@entsize}"
    end

    class Flags < Value
      fill({
             0x00000001 => [ :Write, 'Writable' ],
             0x00000002 => [ :Alloc, 'Allocated' ],
             0x00000004 => [ :ExecInstr, 'Executable' ],
             0x00000010 => [ :Merge, 'Mergeable' ],
             0x00000020 => [ :Strings, 'Contains null-terminated strings' ],
             0x00000040 => [ :InfoLink, 'sh_info contains SHT index' ],
             0x00000080 => [ :LinkOrder, 'Preserve order after combining' ],
             0x00000100 => [ :OsNonConforming, 'Non-standard OS specific handling required' ],
             0x00000200 => [ :Group, 'Section is member of a group' ],
             0x00000400 => [ :TLS, 'Section hold thread-local data' ],
             0x0ff00000 => [ :MaskOS, 'OS-specific flags' ],
             0xf0000000 => [ :MaskProc, 'Processor-specific flags' ],
             0x40000000 => [ :Ordered, 'Special ordering requirement' ],
             0x80000000 => [ :Exclude, 'Section is excluded unless referenced or allocated' ]
           })
    end
  end
end

require 'elf/stringtable'
require 'elf/symboltable'
require 'elf/dynamic'

module Elf
  class Section
    class Type < Value
      fill({
              0 => [ :Null, 'Unused' ],
              1 => [ :ProgBits, 'Program data' ],
              2 => [ :SymTab, 'Symbol table' ],
              3 => [ :StrTab, 'String table' ],
              4 => [ :RelA, 'Relocation entries with addends' ],
              5 => [ :Hash, 'Symbol hash table' ],
              6 => [ :Dynamic, 'Dynamic linking information' ],
              7 => [ :Note, 'Notes' ],
              8 => [ :NoBits, 'Program space with no data (bss)' ],
              9 => [ :Rel, 'Relocation entries, no addends' ],
             10 => [ :ShLib, 'Reserved' ],
             11 => [ :DynSym, 'Dynamic linker symbol table' ],
             14 => [ :InitArray, 'Array of constructors' ],
             15 => [ :FiniArray, 'Array of destructors' ],
             16 => [ :PreinitArray, 'Array of pre-constructors' ],
             17 => [ :Group, 'Section group' ],
             18 => [ :SymTabShndx, 'Extended section indeces' ],
#             0x60000000 => [ :LoOs, 'OS-specific range start' ],
             0x6ffffff6 => [ :GnuHash, 'GNU-style hash table' ],
             0x6ffffff7 => [ :GnuLiblist, 'Prelink library list' ],
             0x6ffffff8 => [ :Checksum, 'Checksum for DSO content' ],
#             0x6ffffffa => [ :LoSunW, 'Sun-specific range start' ],
             0x6ffffffa => [ :SunWMove, nil ],
             0x6ffffffb => [ :SunWComDat, nil ],
             0x6ffffffc => [ :SunWSymInfo, nil ],
             0x6ffffffd => [ :GNUVerDef, 'Version definition section' ],
             0x6ffffffe => [ :GNUVerNeed, 'Version needs section' ],
#             0x6fffffff => [ :HiSunW, 'Sun-specific range end' ],
#             0x6fffffff => [ :HiOs, 'OS-specific range end' ],
             0x6fffffff => [ :GNUVerSym, 'Version symbol table' ],
             0x70000000 => [ :LoProc, 'Processor-specific range start' ],
             0x7fffffff => [ :HiProc, 'Processor-specific range end' ],
             0x80000000 => [ :LoUser, 'Application-specific range start' ],
             0x8fffffff => [ :HiUser, 'Application-specific range end' ]
           })

      Class = {
        StrTab => Elf::StringTable,
        SymTab => Elf::SymbolTable,
        DynSym => Elf::SymbolTable,
        Dynamic => Elf::Dynamic,
        GNUVerSym => Elf::GNU::SymbolVersionTable,
        GNUVerDef => Elf::GNU::SymbolVersionDef,
        GNUVerNeed => Elf::GNU::SymbolVersionNeed
      }

      class ProcARM < Value
        fill({
             0x70000003 => [ :ARMAttributes, 'ARM Attributes' ],
             })
      end
    end
  end
end
