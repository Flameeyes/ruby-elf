# -*- coding: utf-8 -*-
# Copyright © 2007-2010 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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
require 'elf/utils/loader'

module Elf::TestRelocatable
  include Elf::TestExecutable

  BaseFilename = "dynamic_executable.o"
  ExpectedFileType = Elf::File::Type::Rel

  PrintfSymname = "printf"

  # Test for _not_ of .dynamic section on the file.
  # This is a prerequisite for static executable files.
  def test_static
    assert(!@elf.has_section?('.dynamic'),
           ".dynamic section present on ELF file #{@elf.path}")
  end

  def test_find_symbol
    sym = @elf['.symtab'].find do |sym|
      sym.name == self.class::PrintfSymname
    end

    assert_equal(self.class::PrintfSymname, sym.name)
    assert(!sym.defined?)
  end

  def test_find_all_symbols
    syms = @elf['.symtab'].find_all do |sym|
      sym.name == self.class::PrintfSymname
    end

    assert_equal(1, syms.size)

    sym = syms[0]
    assert_equal(self.class::PrintfSymname, sym.name)
    assert(!sym.defined?)
  end

  def test_symbols_to_set
    symbols_set = @elf['.symtab'].to_set

    assert_kind_of(Set, symbols_set)
    assert_equal(@elf['.symtab'].size,
                 symbols_set.size)
  end

  def test_defined_symbols
    sym = @elf['.symtab'].find do |sym|
      sym.name == self.class::PrintfSymname
    end

    defined_syms = @elf[".symtab"].defined_symbols

    assert_kind_of(Set, defined_syms)
    assert(!defined_syms.include?(sym))
  end

  class LinuxX86 < Test::Unit::TestCase
    include Elf::TestRelocatable
    include Elf::TestExecutable::LinuxX86
  end

  class LinuxAMD64 < Test::Unit::TestCase
    include Elf::TestRelocatable
    include Elf::TestExecutable::LinuxAMD64
  end
 
  class LinuxAMD64_ICC < Test::Unit::TestCase
    Compiler = "icc"
    include Elf::TestRelocatable
    include Elf::TestExecutable::LinuxAMD64

    ExpectedABI = Elf::OsAbi::Linux
  end

  class LinuxAMD64_SunStudio < Test::Unit::TestCase
    Compiler = "suncc"
    include Elf::TestRelocatable
    include Elf::TestExecutable::LinuxAMD64
  end
 
  class LinuxSparc < Test::Unit::TestCase
    include Elf::TestRelocatable
    include Elf::TestExecutable::LinuxSparc
    ExpectedMachine = Elf::Machine::Sparc
  end

  class LinuxArm < Test::Unit::TestCase
    include Elf::TestRelocatable
    include Elf::TestExecutable::LinuxArm
  end

  class BareH8300 < Test::Unit::TestCase
    BaseFilename = "static_executable.o"
    include Elf::TestRelocatable
    include Elf::TestExecutable::BareH8300
    PrintfSymname = "_printf"
  end

  class SolarisX86_GCC < Test::Unit::TestCase
    include Elf::TestRelocatable
    include Elf::TestExecutable::SolarisX86_GCC
  end

  class SolarisX86_SunStudio < Test::Unit::TestCase
    include Elf::TestRelocatable
    include Elf::TestExecutable::SolarisX86_SunStudio
  end

  def self.subsuite
    suite = Test::Unit::TestSuite.new("Relocatable objects")
    suite << LinuxX86.suite
    suite << LinuxAMD64.suite
    suite << LinuxAMD64_ICC.suite
    suite << LinuxAMD64_SunStudio.suite
    suite << LinuxSparc.suite
    suite << LinuxArm.suite
    suite << BareH8300.suite
    suite << SolarisX86_GCC.suite
    suite << SolarisX86_SunStudio.suite
  end
end
