# -*- coding: utf-8 -*-
# Copyright © 2007-2009 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

class TC_Relocatable < Elf::TestExecutable
  BaseFilename = "dynamic_executable.o"
  ExpectedFileType = Elf::File::Type::Rel

  # Test for _not_ of .dynamic section on the file.
  # This is a prerequisite for static executable files.
  def test_static
    assert(!@elf.has_section?('.dynamic'),
           ".dynamic section present on ELF file #{@elf.path}")
  end

  class LinuxX86 < self
    include Elf::TestExecutable::LinuxX86
  end

  class LinuxAMD64 < self
    include Elf::TestExecutable::LinuxAMD64
  end
 
  class LinuxAMD64_ICC < self
    Compiler = "icc"
    include Elf::TestExecutable::LinuxAMD64

    ExpectedABI = Elf::OsAbi::Linux
  end

  class LinuxAMD64_SunStudio < self
    Compiler = "suncc"
    include Elf::TestExecutable::LinuxAMD64
  end
 
  class LinuxSparc < self
    include Elf::TestExecutable::LinuxSparc
    ExpectedMachine = Elf::Machine::Sparc
  end

  class LinuxArm < self
    include Elf::TestExecutable::LinuxArm
  end

  class BareH8300 < self
    BaseFilename = "static_executable.o"
    include Elf::TestExecutable::BareH8300
  end

  class SolarisX86_GCC < self
    include Elf::TestExecutable::SolarisX86_GCC
  end

  class SolarisX86_SunStudio < self
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
