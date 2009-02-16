# -*- coding: utf-8 -*-
# Copyright © 2009 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

require 'elf'
require 'elf/utils/pool'

# This file provides some utilities to deal with the runtime lodader
# functions. In particular it provides access to the same kind of
# library search as the loader provides.

module Elf
  module Utilities
    @@library_path = nil

    # Return the system library path to look for libraries, just like
    # the loader would.
    def self.system_library_path

      # Try to cache the request since we most likely have multiple
      # request per process and we don't care if the settings change
      # between them.
      if @@library_path.nil?
        @@library_path = []
        # This implements for now the glibc-style loader
        # configuration; in the future it might be reimplemented to
        # take into consideration different operating systems.
        ::File.open("/etc/ld.so.conf") do |ld_so_conf|
          ld_so_conf.each_line do |line|
            # Comment lines in the configuration file are prefixed
            # with the hash character, and the remaining content is
            # just a single huge list of paths, separated by colon,
            # comma, space, tabs or newlines.
            @@library_path.concat line.gsub(/#.*/, '').split(/[:, \t\n]/)
          end
        end
      end
      
      return @@library_path
    end
  end

  # Extend the Dynamic section class. Instead of adding the following
  # functions to all ELF files and then checking that they indeed are
  # valid dynamic ELF files add them to @elf[".dynamic"] so that they
  # are safely used.
  class Dynamic < Section
    # Return the ELF library corresponding to the given soname.
    #
    # This function gets the system library paths and eventually adds
    # the rpaths as expressed by the file itself, then look them up to
    # find the proper library, just like the loader would.
    def find_library(soname)
      # We need for this to be an array since it's ordered and sets
      # aren't.
      library_path = []

      # We need to find DT_RPATH and DT_RUNPATH entries. It is allowed
      # to have more than one so iterate over all of them.
      each_entry do |entry|
        case entry.type
        when Elf::Dynamic::Type::RPath, Elf::Dynamic::Type::RunPath
          library_path.concat entry.parsed.split(":")
        end
      end

      # Now add to that the system library path
      library_path += Elf::Utilities.system_library_path

      library_path.each do |path|
        if FileTest.exist? "#{path}/#{soname}"
          begin
            possible_library = Elf::Utilities::FilePool["#{path}/#{soname}"]
            
            return possible_library if @file.is_compatible(possible_library)
          rescue Errno::ENOENT, Errno::EACCES, Errno::EISDIR, Elf::File::NotAnELF
            # we don't care if the file does not exist and similar.
          end
        end
      end

      return nil
    end

    # Returns an hash representing the dependencies of the ELF file.
    #
    # This function reads the .dynamic section of the file for
    # DT_NEEDED entries, then looks for them and add them to an hash.
    #
    # Note that nil values int he hash means that the library couldn't
    # be found on either the runpath of the file or the system library
    # path.
    def needed_libraries
      # Make sure to cache the thing, we don't want to have to parse
      # this multiple times since we might access it over and over to
      # check the dependencies.
      if @needed_libraries.nil?
        @needed_libraries = Hash.new

        each_entry do |entry|
          next unless entry.type == Elf::Dynamic::Type::Needed

          @needed_libraries[entry.parsed] = find_library(entry.parsed)
        end
      end

      return @needed_libraries
    end
  end

  class File
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
