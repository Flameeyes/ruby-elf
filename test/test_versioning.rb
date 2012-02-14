# -*- coding: utf-8 -*-
# Copyright © 2008-2010 Diego Elio Pettenò <flameeyes@flameeyes.eu>
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

# Test for GNU versioning support
#
# GNU binutils and glibc support a versioning feature that allows to
# create symbols with multiple versions; this test ensures that
# ruby-elf can read the versioning information correctly.
module Elf::TestVersioning
  include Elf::FullTest
  Os = "linux"
  Compiler = "gcc"
  BaseFilename = "versioning.so"
  ExpectedSections = [".gnu.version", ".gnu.version_d", ".gnu.version_r"]

  ExpectedSectionTypes = {
    ".gnu.version"   => Elf::Section::Type::GNU::VerSym,
    ".gnu.version_d" => Elf::Section::Type::GNU::VerDef,
    ".gnu.version_r" => Elf::Section::Type::GNU::VerNeed
  }

  ExpectedSectionClasses = {
    ".gnu.version"   => Elf::GNU::SymbolVersionTable,
    ".gnu.version_d" => Elf::GNU::SymbolVersionDef,
    ".gnu.version_r" => Elf::GNU::SymbolVersionNeed
  }

  # ignore some of the common tests that we don't really care about.
  undef test_version, test_elf_filetype, test_elf_class,
  test_elf_dataencoding, test_elf_abi, test_elf_abi_version

  def test__gnu_version
    assert_equal(@elf[".dynsym"].count, @elf[".gnu.version"].count,
                 "Wrong version information count")
  end

  def test__gnu_version_d
    section = @elf[".gnu.version_d"]
    
    # We always have a "latent" version with the soname of the
    # library, which is the one used by --default-symver option of GNU
    # ld.
    assert_equal(2, section.count,
                 "Wrong amount of versions defined")

    assert_equal(1, section[1][:names].size,
                 "First version has more than one expected name")
    assert_equal(File.basename(@elf.path), section[1][:names][0],
                 "First version name does not coincide with the filename")
    assert_equal(Elf::GNU::SymbolVersionDef::FlagBase, section[1][:flags] & Elf::GNU::SymbolVersionDef::FlagBase,
                  "First version does not report as base version")

    assert_equal(1, section[2][:names].size,
                 "Second version has more than one expected name")
    assert_equal("VERSION1", section[2][:names][0],
                 "Second version name is not what is expected")
  end

  def test__gnu_version_r
    section = @elf[".gnu.version_r"]

    assert_equal(self.class::ExpectedRequiredVersions, section.count,
                 "Wrong amount of needed versions")

    # The indexes are incremental between defined and needed
    assert(section[3],
           "Version with index 3 not found.")

    assert_equal(self.class::ExpectedGlibcVersion, section[3][:name],
                 "The needed version is not the right name")
  end

  def test_symbols
    first_asymbol_seen = false
    @elf[".dynsym"].each do |sym|
      case sym.name
      when "tolower"
        assert_equal(self.class::ExpectedGlibcVersion, sym.version,
                     "Imported \"tolower\" symbol is not reporting the expected version")
      when "asymbol"
        unless first_asymbol_seen
          assert_equal("VERSION1", sym.version,
                       "Defined symbol \"asymbol\" is not reporting the expected version")
          assert_equal(true, sym.version_default?,
                       "Defined symbol \"asymbol\" with version \"VERSION1\" is not reported as default symbol")
          first_asymbol_seen = true
        else
          assert_equal('', sym.version,
                        "Defined symbol \"asymbol\" is reporting an unexpected version")
        end
      end
    end
  end

  class LinuxAMD64 < Test::Unit::TestCase
    Arch = "amd64"
    ExpectedGlibcVersion = "GLIBC_2.2.5"
    ExpectedRequiredVersions = 1
    include Elf::TestVersioning
  end

  class LinuxX86 < Test::Unit::TestCase
    Arch = "x86"
    ExpectedGlibcVersion = "GLIBC_2.0"
    ExpectedRequiredVersions = 2
    include Elf::TestVersioning
  end
end
