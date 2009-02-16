# -*- coding: utf-8 -*-
# Simple ELF parser for Ruby
#
# Copyright © 2007-2009 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

require 'bytestream-reader'

module Elf
  class File < ::File
    include BytestreamReader

    class NotAnELF < Exception
      def initialize
        super("not a valid ELF file")
      end
    end

    class InvalidElfClass < Exception
      def initialize(klass)
        super("Invalid Elf Class #{klass}")
      end
    end

    class InvalidDataEncoding < Exception
      def initialize(encoding)
        super("Invalid Elf Data Encoding #{encoding}")
      end
    end

    class UnsupportedElfVersion < Exception
      def initialize(version)
        super("Unsupported Elf version #{version}")
      end
    end

    class InvalidOsAbi < Exception
      def initialize(abi)
        super("Invalid Elf ABI #{abi}")
      end
    end

    class InvalidElfType < Exception
      def initialize(type)
        super("Invalid Elf type #{type}")
      end
    end

    class InvalidMachine < Exception
      def initialize(machine)
        super("Invalid Elf machine #{machine}")
      end
    end

    class Type < Value
      fill({
             0 => [ :None, 'No file type' ],
             1 => [ :Rel, 'Relocatable file' ],
             2 => [ :Exec, 'Executable file' ],
             3 => [ :Dyn, 'Shared object file' ],
             4 => [ :Core, 'Core file' ]
           })

      # OS-specific range
      LoOs = 0xfe00
      HiOs = 0xfeff
      
      # Processor-specific range
      LoProc = 0xff00
      HiProc = 0xffff
    end

    attr_reader :elf_class, :data_encoding, :type, :version, :abi,
                :abi_version, :machine
    attr_reader :string_table

    def read_addr
      case @elf_class
      when Class::Elf32 then read_u32
      when Class::Elf64 then read_u64
      end
    end

    def read_off
      case @elf_class
      when Class::Elf32 then read_u32
      when Class::Elf64 then read_u64
      end
    end

    alias :read_half :read_u16

    alias :read_word :read_u32
    alias :read_sword :read_s32

    alias :read_xword :read_u64
    alias :read_sxword :read_s64

    alias :read_section :read_u16
    alias :read_versym :read_half
    
    def initialize(path)
      super(path, "rb")

      begin
        raise NotAnELF unless readexactly(4) == MagicString
      rescue EOFError
        raise NotAnELF
      end

      begin
        @elf_class = Class[read_u8]
      rescue Value::OutOfBound => e
        raise InvalidElfClass.new(e.val)
      end

      begin
        @data_encoding = DataEncoding[read_u8]
      rescue Value::OutOfBound => e
        raise InvalidDataEncoding.new(e.val)
      end

      @version = read_u8
      raise UnsupportedElfVersion.new(@version) if @version > 1

      begin
        @abi = OsAbi[read_u8]
      rescue Value::OutOfBound => e
        raise InvalidOsAbi.new(e.val)
      end
      @abi_version = read_u8

      seek(16, IO::SEEK_SET)
      set_endian(DataEncoding::BytestreamMapping[@data_encoding])

      begin
        @type = Type[read_half]
      rescue Value::OutOfBound => e
        raise InvalidElfType.new(e.val)
      end
      
      begin
        @machine = Machine[read_half]
      rescue Value::OutOfBound => e
        raise InvalidMachine.new(e.val)
      end

      @version = read_word
      @entry = read_addr
      @phoff = read_off
      shoff = read_off
      @flags = read_word
      @ehsize = read_half
      @phentsize = read_half
      @phnum = read_half
      @shentsize = read_half
      shnum = read_half
      shstrndx = read_half

      elf32 = elf_class == Class::Elf32
      @sections = {}

      @sections_data = []
      seek(shoff)
      for i in 1..shnum
        sectdata = {}
        sectdata[:idx]       = i-1
        sectdata[:name_idx]  = read_word
        sectdata[:type_id]   = read_word
        sectdata[:flags_val] = elf32 ? read_word : read_xword
        sectdata[:addr]      = read_addr
        sectdata[:offset]    = read_off
        sectdata[:size]      = elf32 ? read_word : read_xword
        sectdata[:link]      = read_word
        sectdata[:info]      = read_word
        sectdata[:addralign] = elf32 ? read_word : read_xword
        sectdata[:entsize]   = elf32 ? read_word : read_xword
        
        @sections_data << sectdata
      end

      # When the section header string table index is set to zero,
      # there is not going to be a string table in the file, this
      # happens usually when the file is a static ELF file built
      # directly with an assembler.
      #
      # To handle this specific case, set the @string_table attribute
      # to false, that is distinct from nil, and raise
      # MissingStringTable on request. If the string table is not yet
      # loaded raise instead StringTableNotLoaded.
      if shstrndx == 0 or not self[shstrndx].is_a? StringTable
        @string_table = false
      else
        @string_table = self[shstrndx]

        @sections_names = {}
        @sections_data.each do |sectdata|
          @sections_names[@string_table[sectdata[:name_idx]]] = sectdata[:idx]
        end
      end
    end

    class MissingSection < Exception
      def initialize(sect_identifier)
        super("Requested section #{sect_identifier} not found in the file")
      end
    end

    def load_section(sect_idx_or_name)
      if sect_idx_or_name.is_a? Integer
        raise MissingSection.new(sect_idx_or_name) unless
          @sections_data[sect_idx_or_name]

        @sections[sect_idx_or_name] = Section.read(self, @sections_data[sect_idx_or_name])
      else
        raise MissingSection.new(sect_idx_or_name) unless
          @sections_names[sect_idx_or_name]
        
        load_section @sections_names[sect_idx_or_name]

        @sections[sect_idx_or_name] = @sections[@sections_names[sect_idx_or_name]]
      end
    end

    class StringTableNotLoaded < Exception
      def initialize(sect_name)
        super("Requested section '#{sect_name}' but there is no string table yet.")
      end
    end

    class MissingStringTable < Exception
      def initialize(sect_name)
        super("Requested section '#{sect_name}' but the file has no string table.")
      end
    end

    def [](sect_idx_or_name)
      if sect_idx_or_name.is_a? String and not @string_table.is_a? Elf::Section
        raise MissingStringTable.new(sect_idx_or_name) if @string_table == false
        raise StringTableNotLoaded.new(sect_idx_or_name) if @string_table.nil?
      end

      load_section(sect_idx_or_name) unless
        @sections.has_key? sect_idx_or_name

      return @sections[sect_idx_or_name]
    end

    def each_section
      @sections_data.each do |sectdata|
        load_section(sectdata[:idx])
        yield @sections[sectdata[:idx]]
      end
    end

    def find_section_by_addr(addr)
      @sections_data.each do |sectdata|
        next unless sectdata[:addr] == addr
        load_section(sectdata[:idx])
        return @sections[sectdata[:idx]]
      end
    end

    def has_section?(sect_idx_or_name)

      if sect_idx_or_name.is_a? String and not @string_table.is_a? Elf::Section
        return false if @string_table == false
        raise StringTableNotLoaded.new(sect_idx_or_name) if @string_table.nil?
      end

      if sect_idx_or_name.is_a? Integer
        return @sections_data[sect_idx_or_name] != nil
      elsif sect_idx_or_name.is_a? String
        return @sections_names.has_key?(sect_idx_or_name)
      else
        raise TypeError.new("wrong argument type #{sect_idx_or_name.class} (expected String or Integer)")
      end
    end

    def summary
      $stdout.puts "ELF file #{path}"
      $stdout.puts "ELF class: #{@elf_class} #{@data_encoding} ver. #{@version}"
      $stdout.puts "ELF ABI: #{@abi} ver. #{@abi_version}"
      $stdout.puts "ELF type: #{@type} machine: #{@machine}"
      $stdout.puts "Sections:"
      @sections.values.uniq.each do |sh|
        sh.summary
      end

      return nil
    end

    # Checks whether two ELF files are compatible one with the other for linking
    #
    # This function has to check whether two ELF files can be linked
    # together (either at build time or at load time), and thus checks
    # for class, encoding, versioning, ABI and machine type.
    #
    # Note that it explicitly does not check for ELF file type since
    # you can link different type of files together, like an
    # Executable with a Dynamic library.
    def is_compatible(other)
      raise TypeError.new("wrong argument type #{other.class} (expected Elf::File)") unless
        other.is_a? Elf::File

      @elf_class == other.elf_class and
        @data_encoding == other.data_encoding and
        @version == other.version and
        @abi == other.abi and
        @abi_version == other.abi_version and
        @machine == other.machine
    end
  end
end
