# -*- coding: utf-8 -*-
# Simple ELF parser for Ruby
#
# Copyright © 2007-2010 Diego Elio Pettenò <flameeyes@flameeyes.com>
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
  class SymbolTable < Section
    def load_internal
      @symbols = []
      @symbol_names = {}
      for i in 1..(@numentries)
        sym = Symbol.new(@file, self, i-1)
        @symbols << sym
        @symbol_names[sym.name] = sym.idx
      end

      return nil
    end

    # Exception thrown when requesting a symbol that is not in the
    # table
    class UnknownSymbol < Exception
      def initialize(name_or_idx, section)
        super("Symbol #{name_or_idx} not found in section #{section.name}")
      end
    end

    def [](idx)
      load unless @symbols

      if idx.is_a?(Numeric)
        raise UnknownSymbol.new(idx, self) unless @symbols[idx] != nil
        return @symbols[idx]
      elsif idx.respond_to?("to_s")
        idx = idx.to_s
        raise UnknownSymbol.new(idx, self) unless @symbol_names.has_key?(idx)
        return @symbols[@symbol_names[idx]]
      else
        raise TypeError.new("wrong argument type #{sect_idx_or_name.class} (expected String or Integer)")
      end
    end

    # Iterate over each symbols, replaces section.symbol.each
    def each(&block)
      symbols.each(&block)
    end

    include ::Enumerable

    # Return the number of symbols in the section
    def count
      symbols.size
    end

    # Get a set with all the symbols in the table that are defined,
    # ignoring common, absolute and undefined symbols.
    def defined_symbols
      symbols.find_all do |sym|
        sym.defined?
      end.to_set
    end

    private
    def symbols
      load unless @symbols
      @symbols
    end
  end
end

