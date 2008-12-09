# -*- coding: utf-8 -*-
# Simple ELF parser for Ruby
#
# Copyright © 2007-2008 Diego Pettenò <flameeyes@gmail.com>
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
  # GNU extensions to the ELF formats.
  # 'nuff said.
  module GNU
    class SymbolVersionUnknown < Exception
      def initialize(val)
        super("GNU Symbol versioning version #{val} unknown")
      end
    end

    class SymbolVersionTable < Section
      def load_internal
        @versions = []
        for i in 1..(@numentries)
          @versions << @file.read_versym
        end
      end

      def count
        load unless @versions

        @versions.size
      end

      def [](idx)
        load unless @versions

        @versions[idx]
      end
    end

    class SymbolVersionDef < Section
      FlagBase = 0x0001
      FlagWeak = 0x0002

      def load_internal
        link.load # do this now for safety

        @defined_versions = {}
        entry_off = @offset
        loop do
          @file.seek(entry_off)

          entry = {}
          version = @file.read_half
          raise SymbolVersionUnknown.new(version) if version != 1
          entry[:flags] = @file.read_half
          ndx = @file.read_half
          aux_count = @file.read_half
          entry[:hash] = @file.read_word
          name_off = entry_off + @file.read_word
          next_entry_off = @file.read_word

          entry[:names] = []
          for i in 1..aux_count
            @file.seek(name_off)
            entry[:names] << link[@file.read_word]
            next_name_off = @file.read_word
            break unless next_name_off != 0
            name_off += next_name_off
          end

          @defined_versions[ndx] = entry

          break unless next_entry_off != 0

          entry_off += next_entry_off
        end
      end

      def count
        load unless @defined_versions

        @defined_versions.size
      end
 
      def [](idx)
        load unless @defined_versions

        @defined_versions[idx]
      end

      # Allow to iterate over all the versions defined in the ELF
      # file.
      def each_version(&block)
        load unless @defined_versions

        @defined_versions.each_value(&block)
      end
    end

    class SymbolVersionNeed < Section
      def load_internal
        link.load # do this now for safety

        @needed_versions = {}
        loop do
          version = @file.read_half
          raise SymbolVersionUnknown.new(version) if version != 1
          aux_count = @file.read_half
          file = link[@file.read_word]
          # discard the next, it's used for non-sequential reading.
          @file.read_word
          # This one is interesting only when we need to stop the
          # read loop.
          more = @file.read_word != 0

          for i in 1..aux_count
            entry = {}
            
            entry[:file] = file
            entry[:hash] = @file.read_word
            entry[:flags] = @file.read_half

            tmp = @file.read_half # damn Drepper and overloaded values
            entry[:private] = tmp & (1 << 15) == (1 << 15)
            index = tmp & ~(1 << 15)

            entry[:name] = link[@file.read_word]

            @needed_versions[index] = entry

            break unless @file.read_word != 0
          end

          break unless more
        end
      end
 
      def count
        load unless @needed_versions

        @needed_versions.size
      end
 
      def [](idx)
        load unless @needed_versions

        @needed_versions[idx]
      end

      # Allow to iterate over all the versions needed in the ELF
      # file.
      def each_version(&block)
        load unless @needed_versions

        @needed_versions.each_value(&block)
      end
    end
  end
end
