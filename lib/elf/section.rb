# -*- coding: utf-8 -*-
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

    # Reserved sections range
    LoReserve = 0xff00
    HiReserve = 0xffff

    # Processor-specific reserved sections range
    LoProc = 0xff00
    HiProc = 0xff1f

    # OS-specific reserved sections range
    LoOs = 0xff20
    HiOs = 0xff3f

    # Sun-specific reserved sections range
    # Subset of OS-specific reserved sections range
    LoSunW = 0xff3f
    HiSunW = 0xff3f

    SunWIgnore = 0xff3f
    Abs        = 0xfff1 # Absolute symbols
    Common     = 0xfff2 # Common symbols
    XIndex     = 0xffff
    
    class UnknownType < Exception
      def initialize(type_id, section_name)
        @type_id = type_id
        @section_name = section_name
        super(sprintf("Unknown section type 0x%08x for section #{@section_name}", @type_id))
      end

      attr_reader :type_id, :section_name
    end

    # Create a new Section object reading the section's header from
    # the file.
    # This function assumes that the elf file is aligned ad the
    # start of a section header, and returns the file moved at the
    # start of the next header.
    def Section.read(elf, sectdata)
      if sectdata[:type_id] >= Type::LoProc && sectdata[:type_id] <= Type::HiProc
        case elf.machine
        when Elf::Machine::ARM
          type = Type::ProcARM[sectdata[:type_id]]
        else
          begin
            # Accept general processor-specific section type_ids
            type = Type[sectdata[:type_id]]
          rescue Elf::Value::OutOfBound
            # Uknown processor-specific section type_id, provide a dummy
            type = Elf::Value::Unknown.new(sectdata[:type_id], sprintf("SHT_LOPROC+%07x", sectdata[:type_id]-Type::LoProc))
          end
        end
      elsif sectdata[:type_id] >= Type::LoOs && sectdata[:type_id] <= Type::HiOs
        # Unfortunately, even though OS ABIs are well-defined for both
        # GNU/Linux and Solaris, they don't seem to get used at all.
        #
        # For this reason, instead of basing ourselves on (just) the
        # OS ABI, the name of the section is used to identify the type
        # of section to use

        # Don't set the name if there is no string table loaded
        name = elf.string_table ? elf.string_table[sectdata[:name_idx]] : ""
        if elf.abi == Elf::OsAbi::Solaris or
            name =~ /^\.SUNW_/
          type = Type::SunW[sectdata[:type_id]]
        elsif elf.abi == Elf::OsAbi::Linux or
            name =~ /^\.gnu\./
          type = Type::GNU[sectdata[:type_id]]
        else
          # Unknown OS-specific section type_id, provide a dummy
          type = Elf::Value::Unknown.new(sectdata[:type_id], sprintf("SHT_LOOS+%07x", sectdata[:type_id]-Type::LoOs))
        end
      elsif sectdata[:type_id] >= Type::LoUser && sectdata[:type_id] <= Type::HiUser
        if Type.has_key? sectdata[:type_id]
          type = Type[sectdata[:type_id]]
        else
          # Unknown application-specific section type_id, provide a dummy
          type = Elf::Value::Unknown.new(sectdata[:type_id], sprintf("SHT_LOUSER+%07x", sectdata[:type_id]-Type::LoUser))
        end
      else
        if Type.has_key? sectdata[:type_id]
          type = Type[sectdata[:type_id]]
        else
          raise UnknownType.new(sectdata[:type_id], elf.string_table ? elf.string_table[sectdata[:name_idx]] : sectdata[:name_idx])
        end
      end

      if Type::Class[type]
        return Type::Class[type].new(elf, sectdata, type)
      else
        return Section.new(elf, sectdata, type)
      end
    end

    attr_reader :offset, :addr, :type, :size, :file

    def initialize(elf, sectdata, type)
      @file =      elf
      @type =      type
      @name =      sectdata[:name_idx]
      @flags_val = sectdata[:flags_val]
      @addr =      sectdata[:addr]
      @offset =    sectdata[:offset]
      @size =      sectdata[:size]
      @link =      sectdata[:link]
      @info =      sectdata[:info]
      @addralign = sectdata[:addralign]
      @entsize =   sectdata[:entsize]

      @numentries = @size/@entsize unless @entsize == 0
    end

    def ==(other)
      # For the sake of retrocompatibility and code readability,
      # accept these two types as a valid (albeit false) comparison.
      return false if other.nil? or other.is_a? Integer

      raise TypeError.new("wrong argument type #{other.class} (expected Elf::Section)") unless
        other.is_a? Section

      other.file == @file and other.addr == @addr
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
        @link = @file[@link]
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
             0x40000000 => [ :Ordered, 'Special ordering requirement' ],
             0x80000000 => [ :Exclude, 'Section is excluded unless referenced or allocated' ]
           })
      
      # OS-specific flags mask
      MaskOS   = 0x0ff00000
      # Processor-specific flags mask
      MaskProc = 0xf0000000
    end
  end
end

require 'elf/stringtable'
require 'elf/symboltable'
require 'elf/dynamic'
require 'elf/sunw'
require 'elf/gnu'

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
             # OS-specific range start
             0x6ffffff8 => [ :Checksum, 'Checksum for DSO content' ],
             # OS-specific range end
           })

      # Sun-specific range
      LoSunW = 0x6ffffff1
      HiSunW = 0x6fffffff

      class SunW < Value
        fill({
               LoSunW+0x0 => [ :SymSort, nil ],
               LoSunW+0x1 => [ :TLSSort, nil ],
               LoSunW+0x2 => [ :LDynSym, nil ],
               LoSunW+0x3 => [ :DOF, nil ],
               LoSunW+0x4 => [ :Cap, "Software/Hardware Capabilities" ],
               LoSunW+0x5 => [ :Signature, nil ],
               LoSunW+0x6 => [ :Annotate, nil ],
               LoSunW+0x7 => [ :DebugStr, nil ],
               LoSunW+0x8 => [ :Debug, nil ],
               LoSunW+0x9 => [ :Move, nil ],
               LoSunW+0xa => [ :ComDat, nil ],
               LoSunW+0xb => [ :SymInfo, nil ],
               LoSunW+0xc => [ :VerDef, nil ],
               LoSunW+0xd => [ :VerNeed, nil ],
               LoSunW+0xe => [ :VerSym, nil ]
             })
      end

      # Type values for GNU-specific sections. These sections are
      # generally available just for glibc-based systems using GNU
      # binutils, but might be used by other Operating Systems too.
      class GNU < Value
        fill({
               0x6ffffff6 => [ :Hash, 'GNU-style hash table' ],
               0x6ffffff7 => [ :Liblist, 'Prelink library list' ],
               0x6ffffffd => [ :VerDef, 'Version definition section' ],
               0x6ffffffe => [ :VerNeed, 'Version needs section' ],
               0x6fffffff => [ :VerSym, 'Version symbol table' ]
             })
      end

      class ProcARM < Value
        fill({
             0x70000003 => [ :ARMAttributes, 'ARM Attributes' ],
             })
      end

      # OS-specific range
      LoOs = 0x60000000
      HiOs = 0x6fffffff
      
      # Processor-specific range
      LoProc = 0x70000000
      HiProc = 0x7fffffff

      # Application-specific range
      LoUser = 0x80000000
      HiUser = 0x8fffffff

      Class = {
        StrTab => Elf::StringTable,
        SymTab => Elf::SymbolTable,
        DynSym => Elf::SymbolTable,
        Dynamic => Elf::Dynamic,
        GNU::VerSym => Elf::GNU::SymbolVersionTable,
        GNU::VerDef => Elf::GNU::SymbolVersionDef,
        GNU::VerNeed => Elf::GNU::SymbolVersionNeed,
        SunW::Cap => Elf::SunW::Capabilities
      }

    end
  end
end
