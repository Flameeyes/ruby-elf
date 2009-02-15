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
    Elf::Dynamic::Type::Needed => "self.class::ExpectedLibC"
  }

  ExpectedDynamicLinks = {
    Elf::Dynamic::Type::Init   => ".init",
    Elf::Dynamic::Type::Fini   => ".fini",
    Elf::Dynamic::Type::Hash   => ".hash",
    Elf::Dynamic::Type::StrTab => ".dynstr",
    Elf::Dynamic::Type::SymTab => ".dynsym"
  }
  
  def test_section_values
    @elf[".dynamic"].each_entry do |entry|
      if self.class::ExpectedDynamicValues.has_key? entry.type
        assert_equal(eval(self.class::ExpectedDynamicValues[entry.type]),
                     entry.parsed, "Testing #{entry.type}")
      end
    end
  end

  def test_section_links
    @elf[".dynamic"].each_entry do |entry|
      if self.class::ExpectedDynamicLinks.has_key? entry.type
        assert_equal(@elf[self.class::ExpectedDynamicLinks[entry.type]],
                     entry.parsed, "Testing #{entry.type}")
      end
    end
  end

  def dotest_entry_type(type, fail_notfound = true)
    @elf[".dynamic"].each_entry do |entry|
      if entry[:type] == type
        yield entry
        return
      end
    end

    flunk("#{type} entry not found in .dynamic")
  end

  module GLIBC
    ExpectedDynamicLinks = TC_Dynamic_Executable::ExpectedDynamicLinks.
      merge({
              Elf::Dynamic::Type::GNUHash => ".gnu.hash"
            })

    ExpectedLibC = "libc.so.6"
  end

  class LinuxX86 < self
    include Elf::TestExecutable::LinuxX86
    include GLIBC
  end

  class LinuxAMD64 < self
    include Elf::TestExecutable::LinuxAMD64
    include GLIBC
  end

  class LinuxAMD64_ICC < self
    Compiler = "icc"
    include Elf::TestExecutable::LinuxAMD64
    include GLIBC
  end

  class LinuxAMD64_SunStudio < self
    ExpectedLibC = "libc.so.6"
    include Elf::TestExecutable::LinuxAMD64
  end

  class LinuxSparc < self
    include Elf::TestExecutable::LinuxSparc
    include GLIBC
  end

  class LinuxArm < self
    include Elf::TestExecutable::LinuxArm
    include GLIBC
  end

  class SolarisX86_GCC < self
    ExpectedLibC = "libc.so.1"
    include Elf::TestExecutable::SolarisX86_GCC
  end

  class SolarisX86_SunStudio < self
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
