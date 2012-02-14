# -*- coding: utf-8 -*-
# Copyright © 2007-2010 Diego Elio Pettenò <flameeyes@flameeyes.eu>
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

require 'tt_elf'

# Test proper handling of Executable ELF files.
module Elf::TestSharedObject
  include Elf::TestExecutable

  BaseFilename = "versioning.so"
  ExpectedElfFileType = Elf::File::Type::Dyn

  ExpectedSections = Elf::TestExecutable::ExpectedSections +
    [ ".dynamic", ".dynsym", ".dynstr" ]

  ExpectedSectionTypes = {
    ".dynamic" => Elf::Section::Type::Dynamic,
    ".dynsym"  => Elf::Section::Type::DynSym,
    ".dynstr"  => Elf::Section::Type::StrTab
  }

  # Test some values in the .dynamic section.
  #
  # Please note that the value is evaluated since it usually is
  # per-file

  ExpectedDynamicValues = {
    Elf::Dynamic::Type::Needed => "'libc.so.6'",
    Elf::Dynamic::Type::SoName => "'versioning.so'",
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

  def test_soname
    assert_equal("versioning.so", @elf[".dynamic"].soname)
  end

  def test_needed_sonames
    sonames = @elf[".dynamic"].needed_sonames

    assert_equal(1, sonames.size)
    assert_equal("libc.so.6", sonames[0])
  end

  def test_needed_libraries
    libs = @elf[".dynamic"].needed_libraries

    assert_equal(1, libs.size)
    assert(libs.has_key?("libc.so.6"))

    # We cannot test if the library was actually found because we can
    # test objects for foreign OSes
  end

  class LinuxX86 < Test::Unit::TestCase
    Os = "linux"
    Arch = "x86"
    Compiler = "gcc"
    ExpectedEntryPoint = 0x400

    include Elf::TestSharedObject
  end

  class LinuxAMD64 < Test::Unit::TestCase
    Os = "linux"
    Arch = "amd64"
    Compiler = "gcc"
    ExpectedEntryPoint = 0x5a0

    include Elf::TestSharedObject
  end
end
