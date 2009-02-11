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

# Test for special ARM sections.
# ARM ELF files contain an extra section called .ARM.attributes, this
# test is intended to properly check for presence and parsing of this
# section, and to avoid possible misreading of it.
class TC_ARM < Elf::TestUnit
  Os = "linux"
  Arch = "arm"
  Compiler = "gcc"
  BaseFilename = "dynamic_executable.o"

  ExpectedSections = [ ".ARM.attributes" ]
  ExpectedSectionTypes = {
    ".ARM.attributes" => Elf::Section::Type::ProcARM::ARMAttributes
  }
  
  ExpectedSectionTypeClasses = {
    ".ARM.attributes" => Elf::Section::Type::ProcARM
  }

  def test_machine
    assert_equal(Elf::Machine::ARM, @elf.machine,
                 "Wrong ELF machine type")
  end
end
