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
class TC_Dynamic_Executable < Elf::TestExecutable
  BaseFilename = "dynamic_executable"
  ExpectedElfFileType = Elf::File::Type::Exec

  ExpectedSections = Elf::TestExecutable::ExpectedSections +
    [ ".dynamic", ".dynsym", ".dynstr" ]

  ExpectedSectionTypes = {
    ".dynamic" => Elf::Section::Type::Dynamic,
    ".dynsym"  => Elf::Section::Type::DynSym,
    ".dynstr"  => Elf::Section::Type::StrTab
  }

  # Test for presence of an undefined printf symbol.
  def test_printf_symbol
    printf_found = false
    @elf['.dynsym'].each_symbol do |sym|
      next unless sym.name == "printf"
      printf_found = true
      
      assert_equal(Elf::Section::Undef, sym.section,
                   "printf symbol not in Undefined section")
    end
  end

  # Test some values in the .dynamic section.
  #
  # Please note that the value is evaluated since it usually is
  # per-file

  ExpectedDynamicValues = {
    Elf::Dynamic::Type::Needed => "self.class::ExpectedLibC",
    Elf::Dynamic::Type::Init   => "@elf['.init'].addr",
    Elf::Dynamic::Type::Fini   => "@elf['.fini'].addr",
    Elf::Dynamic::Type::Hash   => "@elf['.hash'].addr",
    Elf::Dynamic::Type::StrTab => "@elf['.dynstr'].addr",
    Elf::Dynamic::Type::SymTab => "@elf['.dynsym'].addr",
    Elf::Dynamic::Type::Debug  => "0x0"
  }
  
  def test_section_entries
    @elf[".dynamic"].entries.each do |entry|
      if self.class::ExpectedDynamicValues.has_key? entry[:type]
        assert_equal(eval(self.class::ExpectedDynamicValues[entry[:type]]),
                     entry[:parsed], "Testing #{entry[:type]}")
      end
    end
  end

  def dotest_entry_type(type, fail_notfound = true)
    @elf[".dynamic"].entries.each do |entry|
      if entry[:type] == type
        yield entry
        return
      end
    end

    flunk("#{type} entry not found in .dynamic")
  end

  module GLIBC
    ExpectedDynamicValues = TC_Dynamic_Executable::ExpectedDynamicValues.
      merge({
              Elf::Dynamic::Type::GNUHash => "@elf['.gnu.hash'].addr"
            })
  end

  class LinuxX86 < self
    Filename = "linux_x86_" + BaseFilename
    ExpectedLibC = "libc.so.6"
    include Elf::TestExecutable::LinuxX86
    include GLIBC
  end

  class LinuxAMD64 < self
    Filename = "linux_amd64_" + BaseFilename
    ExpectedLibC = "libc.so.6"
    include Elf::TestExecutable::LinuxAMD64
    include GLIBC
  end

  class LinuxAMD64_ICC < self
    Filename = "linux_amd64_icc_" + BaseFilename
    ExpectedLibC = "libc.so.6"
    include Elf::TestExecutable::LinuxAMD64
    include GLIBC
  end

  class LinuxAMD64_SunStudio < self
    Filename = "linux_amd64_suncc_" + BaseFilename
    ExpectedLibC = "libc.so.6"
    include Elf::TestExecutable::LinuxAMD64
  end

  class LinuxSparc < self
    Filename = "linux_sparc_" + BaseFilename
    ExpectedLibC = "libc.so.6"
    include Elf::TestExecutable::LinuxSparc
    include GLIBC
  end

  class LinuxArm < self
    Filename = "linux_arm_" + BaseFilename
    ExpectedLibC = "libc.so.6"
    include Elf::TestExecutable::LinuxArm
    include GLIBC
  end

  class SolarisX86_GCC < self
    Filename = "solaris_x86_gcc_executable"
    ExpectedLibC = "libc.so.1"
    include Elf::TestExecutable::SolarisX86_GCC
  end

  class SolarisX86_SunStudio < self
    Filename = "solaris_x86_suncc_executable"
    ExpectedLibC = "libc.so.1"
    include Elf::TestExecutable::SolarisX86_SunStudio
  end

  def self.subsuite
    suite = Test::Unit::TestSuite.new("Dynamic executables")
    suite << LinuxX86.suite
    suite << LinuxAMD64.suite
    suite << LinuxAMD64_ICC.suite
    suite << LinuxAMD64_SunStudio.suite
    suite << LinuxSparc.suite
    suite << LinuxArm.suite
    suite << SolarisX86_GCC.suite
    suite << SolarisX86_SunStudio.suite
  end
end
