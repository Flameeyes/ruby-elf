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

# Test proper handling of Executable ELF files.
module Elf::TestDynamicExecutable
  include Elf::TestExecutable

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
    @elf['.dynsym'].each do |sym|
      next unless sym.name == "printf"
      printf_found = true
      
      assert_equal(Elf::Section::Undef, sym.section,
                   "printf symbol not in Undefined section")
    end
  end

  def test_find_symbol
    sym = @elf['.dynsym'].find do |sym|
      sym.name == "printf"
    end

    assert_equal("printf", sym.name)
    assert(!sym.defined?)
  end

  def test_find_all_symbols
    syms = @elf['.dynsym'].find_all do |sym|
      sym.name == "printf"
    end

    assert_equal(1, syms.size)

    sym = syms[0]
    assert_equal("printf", sym.name)
    assert(!sym.defined?)
  end

  def test_symbols_to_set
    symbols_set = @elf['.dynsym'].to_set

    assert_kind_of(Set, symbols_set)
    assert_equal(@elf['.dynsym'].size,
                 symbols_set.size)
  end

  def test_defined_symbols
    sym = @elf['.dynsym'].find do |sym|
      sym.name == "printf"
    end

    defined_syms = @elf[".dynsym"].defined_symbols

    assert_kind_of(Set, defined_syms)
    assert(!defined_syms.include?(sym))
  end

  # Test some values in the .dynamic section.
  #
  # Please note that the value is evaluated since it usually is
  # per-file

  ExpectedDynamicValues = {
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

  # Tests the Elf::File#needed_sonames function.
  def test_needed_sonames
    assert_equal([self.class::ExpectedLibC],
                 @elf[".dynamic"].needed_sonames)
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
    ExpectedDynamicLinks = Elf::TestDynamicExecutable::ExpectedDynamicLinks.
      merge({
              Elf::Dynamic::Type::GNUHash => ".gnu.hash"
            })

    ExpectedLibC = "libc.so.6"
  end

  class LinuxX86 < Test::Unit::TestCase
    include Elf::TestDynamicExecutable
    include Elf::TestExecutable::LinuxX86
    include GLIBC
  end

  class LinuxAMD64 < Test::Unit::TestCase
    include Elf::TestDynamicExecutable
    include Elf::TestExecutable::LinuxAMD64
    include GLIBC
  end

  class LinuxAMD64_ICC < Test::Unit::TestCase
    Compiler = "icc"
    include Elf::TestDynamicExecutable
    include Elf::TestExecutable::LinuxAMD64
    include GLIBC
  end

  class LinuxAMD64_SunStudio < Test::Unit::TestCase
    ExpectedLibC = "libc.so.6"
    include Elf::TestDynamicExecutable
    include Elf::TestExecutable::LinuxAMD64
  end

  class LinuxSparc < Test::Unit::TestCase
    include Elf::TestDynamicExecutable
    include Elf::TestExecutable::LinuxSparc
    include GLIBC
  end

  class LinuxArm < Test::Unit::TestCase
    include Elf::TestDynamicExecutable
    include Elf::TestExecutable::LinuxArm
    include GLIBC
  end

  class SolarisX86_GCC < Test::Unit::TestCase
    ExpectedLibC = "libc.so.1"
    include Elf::TestDynamicExecutable
    include Elf::TestExecutable::SolarisX86_GCC

    # We can write this test for the only reason that the file is
    # currently built with Gentoo Prefix on OpenSolaris, so pay
    # attention to this!
    def test_rpath
      assert_equal(["/opt/gentoo/usr/i386-pc-solaris2.11/lib/gcc", "/opt/gentoo/usr/i386-pc-solaris2.11/lib", "/opt/gentoo/usr/lib", "/opt/gentoo/lib"],
                   @elf[".dynamic"].rpath)
    end

    def test_runpath
      assert_equal(["/opt/gentoo/usr/i386-pc-solaris2.11/lib/gcc", "/opt/gentoo/usr/i386-pc-solaris2.11/lib", "/opt/gentoo/usr/lib", "/opt/gentoo/lib"],
                   @elf[".dynamic"].runpath)
    end
  end

  class SolarisX86_SunStudio < Test::Unit::TestCase
    ExpectedLibC = "libc.so.1"
    include Elf::TestDynamicExecutable
    include Elf::TestExecutable::SolarisX86_SunStudio
  end
end
