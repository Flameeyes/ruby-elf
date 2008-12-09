# -*- coding: utf-8 -*-
# Copyright 2008, Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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
class TC_StringTable < Elf::TestUnit
  Filename = "linux_amd64_symboltypes.o"
  ExpectedSections = [".strtab"]

  ExpectedSectionTypes = {
    ".strtab" => Elf::Section::Type::StrTab
  }

  ExpectedSectionClasses = {
    ".strtab" => Elf::StringTable
  }

  # Test the first empty string.
  def test_first_empty
    assert_equal("", @elf[".strtab"][0])
  end

  # Test the final empty string.
  def test_final_empty
    assert_equal("",
                 @elf[".strtab"][@elf[".strtab"].size-1])
  end

  def test_filename
    assert_equal("symboltypes.c",
                 @elf[".strtab"][1])
  end
  
  def test_partial_filename
    assert_equal("types.c",
                 @elf[".strtab"][1+6])
  end

  # Test behaviour when providing an invalid index
  #
  # Expected behaviour: Elf::StringTable::InvalidIndex exception
  # raised.
  def test_invalid_index
    assert_raise Elf::StringTable::InvalidIndex do
      @elf[".strtab"][@elf[".strtab"].size]
    end
  end
end

