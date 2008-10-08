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

# Test for GNU versioning support
#
# GNU binutils and glibc support a versioning feature that allows to
# create symbols with multiple versions; this test ensures that
# ruby-elf can read the versioning information correctly.
class TC_Versioning < Test::Unit::TestCase
  TestDir = Pathname.new(__FILE__).dirname + "binaries"

  def setup
    @elf = Elf::File.new(TestDir + "linux_amd64_versioning.so")
  end

  def teardown
    @elf.close
  end

  def test_sections_presence
    [".gnu.version", ".gnu.version_d", ".gnu.version_r"].each do |sect|
      assert(@elf[sect],
             "Missing section #{sect}")
    end
  end

  def test_sections_types
    assert_equal(Elf::Section::Type::GNU::VerSym, @elf[".gnu.version"].type,
                 "Section .gnu.version of wrong type")
    assert_equal(Elf::Section::Type::GNU::VerDef, @elf[".gnu.version_d"].type,
                 "Section .gnu.version_d of wrong type")
    assert_equal(Elf::Section::Type::GNU::VerNeed, @elf[".gnu.version_r"].type,
                 "Section .gnu.version_r of wrong type")
  end

  def test_sections_classes
    assert_equal(Elf::GNU::SymbolVersionTable, @elf[".gnu.version"].class,
                 "Section .gnu.version of wrong class")
    assert_equal(Elf::GNU::SymbolVersionDef, @elf[".gnu.version_d"].class,
                 "Section .gnu.version_d of wrong class")
    assert_equal(Elf::GNU::SymbolVersionNeed, @elf[".gnu.version_r"].class,
                 "Section .gnu.version_r of wrong class")
  end

  def test__gnu_version
    assert_equal(@elf[".dynsym"].symbols.size, @elf[".gnu.version"].count,
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
    assert_equal(Pathname(@elf.path).basename.to_s, section[1][:names][0],
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

    
    assert_equal(1, section.count,
                 "Wrong amount of needed versions")

    # The indexes are incremental between defined and needed
    assert(section[3],
           "Version with index 3 not found.")

    assert_equal("GLIBC_2.2.5", section[3][:name],
                 "The needed version is not the right name")
  end

  def test_symbols
    first_asymbol_seen = false
    @elf[".dynsym"].symbols.each do |sym|
      case sym.name
      when "tolower"
        assert_equal("GLIBC_2.2.5", sym.version,
                     "Imported \"tolower\" symbol is not reporting the expected version")
      when "asymbol"
        unless first_asymbol_seen
          assert_equal("VERSION1", sym.version,
                       "Defined symbol \"asymbol\" is not reporting the expected version")
          first_asymbol_seen = true
        else
          assert_equal(nil, sym.version,
                        "Defined symbol \"asymbol\" is reporting an unexpected version")
        end
      end
    end
  end

end

