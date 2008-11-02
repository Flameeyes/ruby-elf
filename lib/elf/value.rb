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

module Elf
  class Value
    class OutOfBound < Exception
      attr_reader :val

      def initialize(val)
        @val = val
        @appendix = ""
      end

      def message
        "Value #{@val} out of bound#{@appendix}"
      end
      
      def append_message(s)
        @appendix << "\n#{s}"
      end
    end

    def initialize(val, params)
      @val = val
      @desc = params[1]
    end

    attr_reader :desc, :val
    alias :to_i :val
    alias :to_s :desc

    def ==(other)
      self.class == other.class and @val == other.to_i
    end

    def Value.[](idx)
      raise OutOfBound.new(idx) unless @enums[idx]

      @enums[idx]
    end

    def Value.has_key?(idx)
      @enums.has_key?(idx)
    end

    def Value.fill(hash)
      @enums = { }

      hash.each_pair do |index, value|
        @enums[index] = self.new(index, value)
        const_set(value[0], @enums[index])
      end
    end

    def Value.each(&block)
      @enums.each_value(&block)
    end

    # Class for unknown values
    #
    # This class is used to provide a way to access at least basic
    # data for values that are not known but are known valid (like OS-
    # or CPU-specific types for files, sections and symbols).
    #
    # It mimics the basis of a Value but is custom-filled by the using
    # code.
    class Unknown
      def initialize(val, desc)
        @val = val
        @desc = desc
      end

      attr_reader :desc, :val
      alias :to_i :val
      alias :to_s :desc
    end
  end
end
