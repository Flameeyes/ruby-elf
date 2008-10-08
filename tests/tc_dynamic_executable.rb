# Copyright 2007, Diego "Flameeyes" Pettenò <flameeyes@gmail.com>
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

# Test proper handling of Executable ELF files.
class TC_Dynamic_Executable < Test::Unit::TestCase
  TestBaseFilename = "dynamic_executable"
  TestElfType = Elf::File::Type::Exec
  include ElfTests

  # Test for presence of .dynamic section on the file.
  # This is a prerequisite for dynamic executable files.
  def test_dynamic
    @elfs.each_pair do |name, elf|
      assert(elf['.dynamic'],
             "Missing .dynamic section on ELF file #{elf.path}")
      assert_equal(Elf::Section::Type::Dynamic, elf['.dynamic'].type,
             "Wrong type for section .dynamic (expected Elf::Section::Type::Dynamic, got #{elf['.dynamic'].type})")
    end
  end

  # Test for the presence of .dynsym section on the file.
  def test_dynsym_presence
    @elfs.each_pair do |name, elf|
      assert(elf['.dynsym'],
             "Missing .dynsym section on ELF file #{elf.path}")
      assert_equal(Elf::Section::Type::DynSym, elf['.dynsym'].type,
                   "Wrong type for section .dynsym (expected Elf::Section::Type::DynSym, got #{elf['.dynsym'].type})")
    end
  end

  # Test for presence of an undefined printf symbol.
  def test_printf_symbol
    @elfs.each_pair do |name, elf|
      printf_found = false
      elf['.dynsym'].symbols.each do |sym|
        next unless sym.name == "printf"
        printf_found = true
        
        assert_equal(Elf::Section::Undef, sym.section,
                     "printf symbol not in Undefined section")
      end
      assert(printf_found, "printf symbol not found")
    end
  end
end
