# -*- coding: utf-8 -*-
# Simple ELF parser for Ruby
#
# Copyright © 2007-2010 Diego Elio Pettenò <flameeyes@flameeyes.eu>
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

      OsSpecific = 10..12
      ProcSpecific = 13..15

      SpecialRanges = {
        "STB_LOOS" => OsSpecific,
        "STB_LOPROC" => ProcSpecific
      }
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

      OsSpecific = 10..12
      ProcSpecific = 13..15
      SpecialRanges = {
        "STT_LOOS" => OsSpecific,
        "STT_LOPROC" => ProcSpecific
      }
    end

    class Visibility < Value
      fill(
           0 => [ :Default, 'Default visibility' ],
           1 => [ :Internal, 'Processor-specific hidden visibility' ],
           2 => [ :Hidden, 'Hidden visibility' ],
           3 => [ :Protected, 'Protected visibility' ],
           4 => [ :Exported, 'Exported symbol' ],
           5 => [ :Singleton, 'Singleton symbol' ],
           6 => [ :Eliminate, 'Symbol to be eliminated' ]
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
        e.append_message(sprintf("While processing symbol %d. Symbol 'info' value: 0x%x",
                                 @idx,
                                 info))
        raise e
      end

      begin
        @visibility = Visibility[@other & 0x03]
      rescue Elf::Value::OutOfBound => e
        e.append_message(sprintf("While procesing symbol %d. Symbol 'other' value: 0x%x",
                                 @idx,
                                 other))
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
        rescue Utilities::OffsetTable::InvalidIndex
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
      # bit 15 is meant to say that this symbol is _not_ the default
      # version to link to; we don't care about that here so we simply
      # ignore its presence.
      version_idx = version_index & ~(1 << 15)

      return nil unless version_idx && version_idx >= 1

      return '' if version_idx == 1

      begin
        if section.nil?
          return @file['.gnu.version_r'][version_idx][:name]
        else
          return @file['.gnu.version_d'][version_idx][:names][0]
        end
      rescue Elf::File::MissingSection
        return @file['.gnu.version_r'][version_idx][:name]
      end
    end

    # the default symbol version is the one that the link editor will
    # use when linking against the library; any symbol is the default
    # symbol unless bit 15 of its version index is set.
    #
    # An undefined symbol cannot be the default symbol
    def version_default?
      !section.nil? and (version_index & (1 << 15) == 0)
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
                    sprintf("%x", symbol.section)
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
                 when Type::Object then 'V'
                   # we cannot use 'v' when value is zero, as for a
                   # variable, a zero address is correct, it's just
                   # functions that cannot be at zero address.
                 when value == 0 then 'w'
                 else 'W'
                 end

      when bind == Binding::GNU::Unique
        nmflag = 'u'

      when section == Elf::Section::Abs
        nmflag = "A"
      when type == Type::Common, section == Elf::Section::Common
        # section check _should_ be limited to objects with
        # Type::Data, but turns out that ICC does not emit
        # uninitialised variables correctly, creating a Type::None
        # object defined in Section::Common. Handle that properly.
        nmflag = 'C'

      when type == Type::Object, type == Type::TLS
        # data object, distinguish between writable or read-only data,
        # as well as data in Section::Type::NoBits sections.
        nmflag = case
                 when section.is_a?(Integer) then nil
                 when !section.flags.include?(Elf::Section::Flags::Write) then "R"
                 when section.type == Elf::Section::Type::NoBits then "B"
                 else "D"
                 end

      when type == Type::None
        # try being smarter than simply reporthing this as a none-type
        # symbol, as some compilers (namely pathCC) emit STT_NONE
        # symbols that are instead functions.
        nmflag = case
                 when section.is_a?(Integer) then "N"
                 when section.flags.include?(Elf::Section::Flags::ExecInstr) then "T"
                 when section.type == Elf::Section::Type::NoBits then "B"
                 else "N"
                 end
      when type == Type::Func
        nmflag = 'T'
      when type == Type::Section
        nmflag = 'S'
      when type == Type::File
        nmflag = 'F'
      when type == Type::GNU::IFunc
        nmflag = 'i'
      end

      # If we haven't found the flag with the above code, we don't
      # know what to use, so raise exception.
      raise UnknownNMCode.new(self) if nmflag.nil?

      nmflag = nmflag.dup

      nmflag.downcase! if bind == Binding::Local

      return nmflag
    end

    # Reports the symbol's address as a string, if any is provided
    #
    # Reports a string full of whitespace if the symbols is not
    # defined (as there is no address)
    def address_string
      section ? sprintf("%0#{@file.address_print_size}x", value) : ''
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

#    begin
#      Demanglers = [  ]
#      def demangle
#        return @demangled if @demangled
#
#        Demanglers.each do |demangler|
#          break if (@demangled ||= demangler.demangle(name))
#        end
#
#        # We're going to remove top-namespace specifications as we don't
#        # need them, but it's easier for the demangler to still emit
#        # them.
#        @demangled.gsub!(/(^| |\()::/, '\1') if @demangled
#
#        return @demangled ||= name
#      end
#    rescue LoadError
      def demangle
        return name
      end
#    end

    private
    def version_index
      return nil if (!@file.has_section?('.gnu.version')) or
        ( section.is_a?(Integer) and section == Elf::Section::Abs ) or
        ( section.is_a? Elf::Section and section.name == ".bss" )

      @file['.gnu.version'][@idx]
    end
  end
end
