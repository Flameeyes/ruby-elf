# -*- coding: utf-8 -*-
# Copyright © 2008-2009 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

require 'test/unit'
require 'pathname'
require 'elf'

# Test handling of symbols tables in ELF files with Ruby-elf
class TC_SymbolTable < Test::Unit::TestCase
  include Elf::BaseTest
  Os = "linux"
  Arch = "amd64"
  Compiler="gcc"
  BaseFilename = "symboltypes.o"
  ExpectedSections = [".symtab", ".strtab"]

  ExpectedSectionTypes = {
    ".symtab" => Elf::Section::Type::SymTab,
    ".strtab" => Elf::Section::Type::StrTab
  }

  ExpectedSectionClasses = {
    ".symtab" => Elf::SymbolTable,
    ".strtab" => Elf::StringTable
  }

  # Test requesting a symbol through its name.
  def test_by_name
    sym = @elf[".symtab"]["external_cold_function"]
    assert_instance_of Elf::Symbol, sym
    assert_equal "external_cold_function", sym.name
  end

  # Test requesting a symbol through its index value
  def test_by_idx
    sym = @elf[".symtab"][1]
    assert_instance_of Elf::Symbol, sym
    assert_equal "symboltypes.c", sym.name
  end

  # Test requesting a symbol through its index value, as float
  def test_by_idx_float
    sym = @elf[".symtab"][1.0]
    assert_instance_of Elf::Symbol, sym
    assert_equal "symboltypes.c", sym.name
  end

  # Test behaviour when asking for a symbol that is not found in a
  # section.
  #
  # Expected behaviour: Elf::SymbolTable::UnknownSymbol is raised.
  def test_unknown_symbol
    assert_raise Elf::SymbolTable::UnknownSymbol do
      @elf[".symtab"]["does_not_exist"]
    end
  end

  # Test behaviour when asking for a symbol that is not found in a
  # section *as an index value*
  #
  # Expected behaviour: Elf::SymbolTable::UnknownSymbol is raised.
  def test_unknown_symbol_idx
    assert_raise Elf::SymbolTable::UnknownSymbol do
      @elf[".symtab"][123]
    end
  end
end

