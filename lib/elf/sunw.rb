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

module Elf
  # Sun-specific sections parsing
  module SunW

    class Capabilities < Section
      class Tag < Value
        fill({
               0 => [ :Null, nil ],
               1 => [ :HW1, "Hardware capabilities" ],
               2 => [ :SF1, "Software capabilities" ]
             })
      end

      def load_internal
        elf32 = @file.elf_class == Class::Elf32

        @entries = []
        loop do
          entry = {}
          tag = elf32 ? @file.read_word : @file.read_xword
          entry[:tag] = Tag[tag]

          # This marks the end of the array.
          break if entry[:tag] == Tag::Null

          # Right now the only two types used make only use of c_val,
          # but in the future there might be capabilities using c_ptr,
          # so prepare for that.
          case entry[:tag]
          when Tag::HW1, Tag::SF1
            entry[:val] = elf32 ? @file.read_word : @file.read_xword
          else
            entry[:ptr] = @file.read_addr
          end

          @entries << entry
        end
      end
      
      def count
        load unless @entries
        
        @entries.size
      end

      def [](idx)
        load unless @entries
        
        @entries[idx]
      end
    end
  end
end
