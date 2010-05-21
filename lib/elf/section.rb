# -*- coding: utf-8 -*-
# Simple ELF parser for Ruby
#
# Copyright © 2007-2010 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
# Portions inspired by elf.py
#   Copyright © 2002 Netgraft Corporation
# Portions inspired by elf.h
#   Copyright © 1995-2006 Free Software Foundation, Inc.
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

    Reserved = 0xff00..0xffff
    ProcSpecific = 0xff00..0xff1f
    OsSpecific = 0xff20..0xff3f

    # Sun-specific range, subset of OS-specific range
    SunW = 0xff3f..0xff3f

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
      begin
        if Type::ProcSpecific.include?(sectdata[:type_id])
          case elf.machine
          when Elf::Machine::ARM
            type = Type::ProcARM[sectdata[:type_id]]
          else
            type = Type[sectdata[:type_id]]
          end
        elsif Type::OsSpecific.include?(sectdata[:type_id])
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
            type = Type[sectdata[:type_id]]
          end
        else
          type = Type[sectdata[:type_id]]
        end
        type = nil if Type.is_a? Value::Unknown
      rescue Value::OutOfBound
        type = nil
      end

      raise UnknownType.new(sectdata[:type_id],
                            elf.string_table ? elf.string_table[sectdata[:name_idx]] : sectdata[:name_idx]
                            ) if type.nil?

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
      fill(
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
           )
      
      # OS-specific flags mask
      MaskOS   = 0x0ff00000
      # Processor-specific flags mask
      MaskProc = 0xf0000000
    end

    # Return the nm(1) code for the section.
    #
    # This function is usually mostly used by Elf::Symbol#nm_code. It
    # moves the parts of the logic that have to deal with section
    # flags and similar here, to stay closer with the section's data
    def nm_code
      @nmflag ||= case
                  when flags.include?(Flags::ExecInstr)
                    "T"
                  when type == Type::NoBits then "B"
                  when type == Type::Note then "N"
                  when name =~ /\.rodata.*/ then "R"
                  when name =~ /\.(t|pic)?data.*/ then "D"
                  else
                    nil
                  end
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
      fill(
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
             0x6ffffff8 => [ :Checksum, 'Checksum for DSO content' ]
             # OS-specific range end
           )

      # Sun-specific range
      SunWSpecific = 0x6ffffff1..0x6fffffff

      class SunW < Value
        fill(
               SunWSpecific.min+0x0 => [ :SymSort, nil ],
               SunWSpecific.min+0x1 => [ :TLSSort, nil ],
               SunWSpecific.min+0x2 => [ :LDynSym, nil ],
               SunWSpecific.min+0x3 => [ :DOF, nil ],
               SunWSpecific.min+0x4 => [ :Cap, "Software/Hardware Capabilities" ],
               SunWSpecific.min+0x5 => [ :Signature, nil ],
               SunWSpecific.min+0x6 => [ :Annotate, nil ],
               SunWSpecific.min+0x7 => [ :DebugStr, nil ],
               SunWSpecific.min+0x8 => [ :Debug, nil ],
               SunWSpecific.min+0x9 => [ :Move, nil ],
               SunWSpecific.min+0xa => [ :ComDat, nil ],
               SunWSpecific.min+0xb => [ :SymInfo, nil ],
               SunWSpecific.min+0xc => [ :VerDef, nil ],
               SunWSpecific.min+0xd => [ :VerNeed, nil ],
               SunWSpecific.min+0xe => [ :VerSym, nil ]
             )
      end

      # Type values for GNU-specific sections. These sections are
      # generally available just for glibc-based systems using GNU
      # binutils, but might be used by other Operating Systems too.
      class GNU < Value
        fill(
               0x6ffffff6 => [ :Hash, 'GNU-style hash table' ],
               0x6ffffff7 => [ :Liblist, 'Prelink library list' ],
               0x6ffffffd => [ :VerDef, 'Version definition section' ],
               0x6ffffffe => [ :VerNeed, 'Version needs section' ],
               0x6fffffff => [ :VerSym, 'Version symbol table' ]
             )
      end

      class ProcARM < Value
        fill(
             0x70000003 => [ :ARMAttributes, 'ARM Attributes' ]
             )
      end

      OsSpecific = 0x60000000..0x6fffffff
      ProcSpecific = 0x70000000..0x7fffffff
      # Application-specific range
      UserSpecific = 0x80000000..0x8fffffff

      SpecialRanges = {
        "SHT_LOOS" => OsSpecific,
        "SHT_LOPROC" => ProcSpecific,
        "SHT_LOUSER" => UserSpecific
      }

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
