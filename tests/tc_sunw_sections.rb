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

# Basic tests for Sun/Solaris-specific sections
#
# Sun ELF files for Solaris contain a few extra sections that are
# Sun-specific extensions, this test checks for their presence and for
# their type and value, to ensure ruby-elf detects them correctly.
class TC_SunW_Sections < Test::Unit::TestCase
  TestDir = Pathname.new(__FILE__).dirname + "binaries"

  def setup
    @elf = Elf::File.new(TestDir + "solaris_x86_suncc_executable")
  end

  def teardown
    @elf.close
  end

  def test_types
    assert_equal(Elf::OsAbi::SysV, @elf.abi,
                 "Expected ABI not found")
    assert_equal(Elf::File::Type::Exec, @elf.type,
                 "Expected ELF Type not found")
  end

  def test_sections_presence
    [".SUNW_cap", ".SUNW_ldynsym", ".SUNW_version",
     ".SUNW_dynsymsort", ".SUNW_reloc"].each do |section|
      assert(@elf.has_section?(section),
             "#{section} section not found")
    end
  end

  def test_sections_type_classes
    [".SUNW_cap", ".SUNW_ldynsym", ".SUNW_version",
     ".SUNW_dynsymsort"].each do |section|
      assert_equal(Elf::Section::Type::SunW, @elf[section].type.class,
                   "#{section} section not of SunW type")
    end
  end

  def test_sections_type_ids
    { ".SUNW_cap"        => 0x6ffffff5,
      ".SUNW_ldynsym"    => 0x6ffffff3,
      ".SUNW_dynsymsort" => 0x6ffffff1 }.each_pair do |name, type_id|
      assert_equal(type_id, @elf[name].type.to_i,
                   "Section #{name} has wrong type ID")
    end
  end

  def test_sunw_cap
    assert(@elf[".SUNW_cap"].is_a?(Elf::SunW::Capabilities),
           "section .SUNW_cap is not of the intended class (#{@elf[".SUNW_cap"].class})")
    assert_equal(1, @elf[".SUNW_cap"].count,
                 "Section .SUNW_cap has wrong entry count")
    assert_equal(Elf::SunW::Capabilities::Tag::HW1, @elf[".SUNW_cap"][0][:tag],
                 "First entry in .SUNW_cap has wrong tag")
    assert(@elf[".SUNW_cap"][0][:flags].include?(Elf::SunW::Capabilities::Hardware1::I386::FPU),
           "the file does not advertise requirement for FPU capabilities")
  end
end
