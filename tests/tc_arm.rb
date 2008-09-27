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

# Test for special ARM sections.
# ARM ELF files contain an extra section called .ARM.attributes, this
# test is intended to properly check for presence and parsing of this
# section, and to avoid possible misreading of it.
class TC_ARM < Test::Unit::TestCase
  TestDir = Pathname.new(__FILE__).dirname + "binaries"

  def setup
    @elf = Elf::File.new(TestDir + "arm-crtn.o")

    assert(@elf.machine == Elf::Machine::ARM,
           "wrong ELF machine type (expected Elf::Machine::ARM, got #{@elf.machine}")
  end

  def teardown
    @elf.close
  end

  def test_section_presence
    assert(@elf.has_section?(".ARM.attributes"),
           ".ARM.attributes section not found.")
  end

  def test_section_type
    assert(@elf[".ARM.attributes"].type == Elf::Section::Type::ProcARM::ARMAttributes,
           "wrong .ARM.attributes type (expected Elf::Section::Type::ProcARM::ARMAttributes, got #{@elf[".ARM.attributes"].type})")
  end

end
