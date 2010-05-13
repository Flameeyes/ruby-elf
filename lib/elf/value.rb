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
      @mnemonic = params[0].to_s
      @desc = params[1]
    end

    attr_reader :desc, :val, :mnemonic
    alias :to_i :val
    alias :to_s :desc

    def ==(other)
      self.class == other.class and @val == other.to_i
    end

    def Value.[](idx)
      return @enums[idx] if @enums[idx]

      # If the Prefix constant is defined for this class, make sure we
      # check for OS- and Proc-specific ranges
      if self.const_defined?("Prefix")
        if self::OsSpecific.include? idx
          return self::Unknown.new(idx, sprintf("%s_LOOS+%x", self::Prefix, idx-self::OsSpecific.min))
        elsif self::ProcSpecific.include? idx
          return self::Unknown.new(idx, sprintf("%s_LOPROC+%x", self::Prefix, idx-self::ProcSpecific.min))
        end
      end

      raise OutOfBound.new(idx)
    end

    def Value.from_string(str)
      str = str.downcase

      each do |value|
        return value if value.mnemonic.downcase == str
      end

      return nil
    end

    def Value.has_key?(idx)
      @enums.has_key?(idx)
    end

    def Value.fill(*hash)
      if hash.size == 1 && hash[0].is_a?(Hash)
        hash = hash[0]
      end

      @enums = { }

      hash.each_pair do |index, value|
        @enums[index] = self.new(index, value)
        const_set(value[0], @enums[index])
      end
    end

    def Value.each(&block)
      @enums.each_value(&block)
    end

    private_class_method :fill

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
