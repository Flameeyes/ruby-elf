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
class TC_SunWSpecific < Test::Unit::TestCase
  TestDir = Pathname.new(__FILE__).dirname + "binaries"

  def setup
    @elf = Elf::File.new(TestDir + "solaris_x86_suncc_executable")
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
    [".SUNW_cap", ".SUNW_ldynsym", ".SUNW_version",
     ".SUNW_dynsymsort", ".SUNW_reloc"].each do |section|
      assert(@elf.has_section?(section),
             "#{section} section not found")
    end
  end

  def test_sections_type_classes
    [".SUNW_cap", ".SUNW_ldynsym", ".SUNW_version",
     ".SUNW_dynsymsort"].each do |section|
      assert(@elf[section].type.class == Elf::Section::Type::SunW,
             "#{section} section not of SunW type: #{@elf[section].type.class}")
    end
  end

  def test_sections_type_ids
    assert(@elf[".SUNW_cap"].type.to_i == 0x6ffffff5,
           "section .SUNW_cap not of type number 0x6ffffff5 (0x#{sprintf "%08x", @elf[".SUNW_cap"].type.to_i})")
    assert(@elf[".SUNW_ldynsym"].type.to_i == 0x6ffffff3,
           "section .SUNW_ldynsym not of type number 0x6ffffff5 (0x#{sprintf "%08x", @elf[".SUNW_ldynsym"].type.to_i})")
    assert(@elf[".SUNW_dynsymsort"].type.to_i == 0x6ffffff1,
           "section .SUNW_dynsymsort not of type number 0x6ffffff5 (0x#{sprintf "%08x", @elf[".SUNW_dynsymsort"].type.to_i})")
  end

  def test_sunw_cap
    assert(@elf[".SUNW_cap"].is_a?(Elf::SunW::Capabilities),
           "section .SUNW_cap is not of the intended class (#{@elf[".SUNW_cap"].class})")
    assert(@elf[".SUNW_cap"].count == 1,
           "section .SUNW_cap has not the expected entries count: #{@elf[".SUNW_cap"].count} rather than 1")
    assert(@elf[".SUNW_cap"][0][:tag] == Elf::SunW::Capabilities::Tag::HW1,
           "first entry in .SUNW_cap is not for hardware capabilities: #{@elf[".SUNW_cap"][0][:tag]}")
    assert(@elf[".SUNW_cap"][0][:flags].include?(Elf::SunW::Capabilities::Hardware1::I386::FPU),
           "the file does not advertise requirement for FPU capabilities")
  end
end
