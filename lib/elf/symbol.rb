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

module Elf
  class Symbol
    class Binding < Value
      fill(
           0 => [ :Local, 'Local symbol' ],
           1 => [ :Global, 'Global symbol' ],
           2 => [ :Weak, 'Weak symbol' ],
           # This one is inferred out of libpam.so
           3 => [ :Number, 'Number of defined type' ]
           )

      class GNU < Value
        fill(
             10 => [ :Unique, 'Unique symbol' ]
             )
      end

      Prefix = "STB"
      OsSpecific = 10..12
      ProcSpecific = 13..15
    end

    class Type < Value
      fill(
           0 => [ :None, 'Unspecified' ],
           1 => [ :Object, 'Data object' ],
           2 => [ :Func, 'Code object' ],
           3 => [ :Section, 'Associated with a section' ],
           4 => [ :File, 'File name' ],
           5 => [ :Common, 'Common data object' ],
           6 => [ :TLS, 'Thread-local data object' ]
           )

      class GNU < Value
        fill(
             10 => [ :IFunc, 'Indirect function' ]
             )
      end

      Prefix = "STT"
      OsSpecific = 10..12
      ProcSpecific = 13..15
    end

    class Visibility < Value
      fill(
           0 => [ :Default, 'Default visibility' ],
           1 => [ :Internal, 'Processor-specific hidden visibility' ],
           2 => [ :Hidden, 'Hidden visibility' ],
           3 => [ :Protected, 'Protected visibility' ],
           4 => [ :Exported, 'Exported symbol' ],
           5 => [ :Singleton, 'Singleton symbol' ],
           6 => [ :Eliminate, 'Symbol to be eliminated' ],
           )
    end

    attr_reader :value, :size, :other, :bind, :type, :idx, :visibility, :file

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
        type_value = info & 0xF
        @type = case
                when Type::OsSpecific.include?(type_value)
                  # Assume always GNU for now, but it's wrong
                  Type::GNU[type_value]
                else
                  Type[type_value]
                end

        binding_value = info >> 4
        @bind = case
                when Binding::OsSpecific.include?(binding_value)
                  # Assume always GNU for now, but it's wrong
                  Binding::GNU[binding_value]
                else
                  Binding[binding_value]
                end

      rescue Elf::Value::OutOfBound => e
        e.append_message("While processing symbol #{@idx}. Symbol info: 0x#{info.hex}")
        raise e
      end

      begin
        @visibility = Visibility[@other & 0x03]
      rescue Elf::Value::OutOfBound => e
        e.append_message("While procesing symbol #{@idx}. Symbol other info: 0x#{@other.hex}")
        raise e
      end

      @file = elf
    end
    
    class InvalidName < Exception
      def initialize(name_idx, sym, symsect)
        super("Invalid name index in #{symsect.link.name} #{name_idx} for symbol #{sym.idx}")
      end
    end

    def name
      # We didn't read the name in form of string yet;
      if @name.is_a? Integer and @symsect.link
        begin
          name = @symsect.link[@name]
        rescue StringTable::InvalidIndex
          raise InvalidName.new(@name, self, @symsect)
        end
        @name = name if name
      end

      @name
    end

    # Alias to_s to name so that using this in a string will report the name
    alias :to_s :name

    def section
      # We didn't read the section yet.
      @section = nil if @section.is_a? Integer and @section == 0
      
      if @section.is_a? Integer and
          not Section::Reserved.include?(@section) and
          @file.has_section?(@section)

        @section = @file[@section]
      end

      @section
    end

    def version
      return nil if (!@file.has_section?('.gnu.version')) or
        ( section.is_a?(Integer) and section == Elf::Section::Abs ) or
        ( section.is_a? Elf::Section and section.name == ".bss" )

      version_idx = @file['.gnu.version'][@idx]
      
      return nil unless version_idx && version_idx >= 2

      name_idx = (version_idx & (1 << 15) == 0) ? 0 : 1
      version_idx2 = version_idx & ~(1 << 15)

      if section.nil? or @file['.gnu.version_d'][version_idx2].nil?
        return @file['.gnu.version_r'][version_idx][:name]
      else
        return @file['.gnu.version_d'][version_idx2][:names][name_idx]
      end
    end

    def defined?
      return false if section.nil?
      return false if section.is_a?(Integer)
      return false if bind == Binding::Weak and value == 0
      return true
    end

    # Exception raised when the NM code for a given symbol is unknown.
    class UnknownNMCode < Exception
      def initialize(symbol)
        section = if symbol.section.nil?
                    nil
                  elsif symbol.section.is_a?(Integer)
                    symbol.section.hex
                  else
                    symbol.section.name
                  end

        super("Unknown NM code for symbol #{symbol.name} in section #{section}")
      end
    end

    # Show the letter code as compatible with GNU nm
    #
    # This function has been moved inside the library since multiple
    # tools based on ruby-elf would be using these code to report
    # symbols, and since the code is complex it's easier to have it
    # here.
    #
    # The resturned value is a one-letter string. The function may
    # raise an UnknownNMCode exception.
    def nm_code
      @nmflag ||= nm_code_internal
    end

    # Convenience function for the first tile the nm code is requested.
    def nm_code_internal
      nmflag = nil

      case
      when idx == 0
        return " "

        # When the section is nil, it means it goes into the Undef
        # section, and the symbol is not defined.
      when section.nil?
        nmflag = "U"

      when bind == Binding::Weak
        nmflag = case type
                 when Type::Object then "V"
                 else "W"
                 end

        nmflag.downcase! if value == 0

      when section.is_a?(Integer)
        nmflag = case section
                 when Elf::Section::Abs then "A"
                 when Elf::Section::Common then "C"
                 else nil
                 end

      else
        # Find the nm(1) code for the section.
        nmflag = section.nm_code
      end

      # If we haven't found the flag with the above code, we don't
      # know what to use, so raise exception.
      raise UnknownNMCode.new(self) if nmflag.nil?

      nmflag = nmflag.dup

      nmflag.downcase! if bind == Binding::Local

      return nmflag
    end

    # Check whether two symbols are the same
    #
    # This function compares the name, version and section of two
    # symbols to tell if they are the same symbol.
    def ==(other)
      return false unless other.is_a? Symbol

      return false unless name == other.name
      return false unless version == other.version

      return false if section == nil and other.section != nil
      return false if section != nil and other.section == nil

      return true
    end

    def eql?(other)
      return self == other
    end

    # Check whether one symbol is compatible with the other
    #
    # This function compares the name and version of two symbols, and
    # ensures that only one of them is undefined; this allows to
    # establish whether one symbol might be satisfied by another.
    def =~(other)
      return false unless other.is_a? Symbol

      return false unless name == other.name
      return false unless version == other.version

      return false if section == nil and other.section == nil
      return false if section != nil and other.section != nil

      return true
    end
  end
end
