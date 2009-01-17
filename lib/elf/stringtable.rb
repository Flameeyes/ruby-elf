# -*- coding: utf-8 -*-
# Simple ELF parser for Ruby
#
# Copyright © 2007 Diego Pettenò <flameeyes@gmail.com>
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

require 'elf/section'

module Elf
  class StringTable < Section
    def load_internal
      @rawtable = @file.readpartial(@size)
    end

    class InvalidIndex < Exception
      def initialize(idx, max_idx)
        super("Invalid index #{idx} (maximum index: #{max_idx})")
      end
    end

    def [](idx)
      load unless @rawtable

      raise InvalidIndex.new(idx, @rawtable.size) if
        idx >= @rawtable.size

      endidx = @rawtable.index("\x00", idx)

      return @rawtable[idx..endidx].chomp("\x00")
    end
  end
end
