# Copyright 2008, Diego "Flameeyes" Pettenò <flameeyes@gmail.com>
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

# Test for unknown OS-specific sections
#
# The binary being used comes from Firefox source tarball and is used
# as a testcase for Google's crash reporting tool; it is peculiar since:
#
# - its filename ends in .o but it's an ET_EXEC file;
# - it does not declare itself as Solaris ABI;
# - it contains Solaris-specific sections (that binutils readelf choke
#   on, bug #6915);
#
# For this reason it's the perfect case for unknown OS-specific
# sections support.
class TC_OsSpecific < Test::Unit::TestCase
  TestDir = Pathname.new(__FILE__).dirname + "binaries"

  def setup
    @elf = Elf::File.new(TestDir + "firefox_solaris_dump_syms_regtest.o")
  end

  def teardown
    @elf.close
  end

  def test_types
    assert(@elf.abi == Elf::OsAbi::SysV,
           "Expected ABI not found (got #{@elf.abi}, wanted Elf::OsAbi::SysV)")
    assert(@elf.type == Elf::File::Type::Exec,
           "Expected ELF Type not found (got #{@elf.type}, wanted Elf::Type::Exec")
  end

  def test_sections_presence
    assert(@elf[".SUNW_cap"],
           ".SUNW_cap section not found")
    assert(@elf[".SUNW_ldynsym"],
           ".SUNW_ldynsym section not found")
    assert(@elf[".SUNW_dynsymsort"],
           ".SUNW_dynsymsort section not found")
  end

  def test_sections_type_classes
    assert(@elf[".SUNW_cap"].type.class == Elf::Value::Unknown,
           "section .SUNW_cap not of unknown type (#{@elf[".SUNW_cap"].type.class})")
    assert(@elf[".SUNW_ldynsym"].type.class == Elf::Value::Unknown,
           "section .SUNW_ldynsym not of unknown type (#{@elf[".SUNW_ldynsym"].type.class})")
    assert(@elf[".SUNW_dynsymsort"].type.class == Elf::Value::Unknown,
           "section .SUNW_dynsymsort not of unknown type (#{@elf[".SUNW_dynsymsort"].type.class})")
  end

  def test_sections_type_ids
    assert(@elf[".SUNW_cap"].type.to_i == 0x6ffffff5,
           "section .SUNW_cap not of type number 0x6ffffff5 (0x#{sprintf "%08x", @elf[".SUNW_cap"].type.to_i})")
    assert(@elf[".SUNW_ldynsym"].type.to_i == 0x6ffffff3,
           "section .SUNW_ldynsym not of type number 0x6ffffff5 (0x#{sprintf "%08x", @elf[".SUNW_ldynsym"].type.to_i})")
    assert(@elf[".SUNW_dynsymsort"].type.to_i == 0x6ffffff1,
           "section .SUNW_dynsymsort not of type number 0x6ffffff5 (0x#{sprintf "%08x", @elf[".SUNW_dynsymsort"].type.to_i})")
  end

  def test_sections_type_names
    assert(@elf[".SUNW_cap"].type.to_s == "SHT_LOOS+ffffff5",
           "section .SUNW_cap name is not the expected one (#{@elf[".SUNW_cap"].type.to_s})")
    assert(@elf[".SUNW_ldynsym"].type.to_s == "SHT_LOOS+ffffff3",
           "section .SUNW_ldynsym name is not the expected one (#{@elf[".SUNW_ldynsym"].type.to_s})")
    assert(@elf[".SUNW_dynsymsort"].type.to_s == "SHT_LOOS+ffffff1",
           "section .SUNW_dynsymsort name is not the expected one (#{@elf[".SUNW_dynsymsort"].type.to_s})")
  end
end
