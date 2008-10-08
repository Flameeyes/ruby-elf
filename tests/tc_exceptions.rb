# Copyright 2007-2008, Diego "Flameeyes" Pettenò <flameeyes@gmail.com>
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

# Test for proper exception handling in the RubyElf library.  This
# test unit should make sure that proper error handling is present
# whenever the file is invalid, contains broken or invalid data, and
# similar.  This test should cover all the possible cases of broken
# ELF files, so that reading a non-ELF file won't cause unexpected
# problems.
class TC_Exceptions < Test::Unit::TestCase
  TestDir = Pathname.new(__FILE__).dirname + "binaries"

  # Test behaviour when a file that is not an ELF file is opened.
  #
  # Expected behaviour: Elf::File::NotAnElf exception is raised.
  def test_notanelf
    assert(File.exist?(TestDir + "invalid_nonelf"),
           "Missing test file invalid_nonelf")

    assert_raise Elf::File::NotAnELF do
      elf = Elf::File.new(TestDir + "invalid_nonelf")
      elf.close
    end
  end

  # Test behaviour when a file too short to be an ELF file is opened
  # (that has not enough data to read the four magic bytes at the
  # start of the file).
  #
  # Expected behaviour: Elf::File::NotAnElf exception is raised.
  def test_shortfile
    assert(File.exist?(TestDir + "invalid_shortfile"),
           "Missing test file invalid_shortfile")

    assert_raise Elf::File::NotAnELF do
      elf = Elf::File.new(TestDir + "invalid_shortfile")
      elf.close
    end
  end

  # Test behaviour when a file with an invalid ELF class value is
  # opened
  #
  # Expected behaviour: Elf::File::InvalidElfClass exception is
  # raised.
  def test_invalid_elfclass
    assert(File.exist?(TestDir + "invalid_invalidclass"),
           "Missing test file invalid_invalidclass")

    assert_raise Elf::File::InvalidElfClass do
      elf = Elf::File.new(TestDir + "invalid_invalidclass")
      elf.close
    end
  end

  # Test behaviour when a file with an invalid ELF data encoding value
  # is opened
  #
  # Expected behaviour: Elf::File::InvalidDataEncoding exception is
  # raised.
  def test_invalid_encoding
    assert(File.exist?(TestDir + "invalid_invalidencoding"),
           "Missing test file invalid_invalidencoding")

    assert_raise Elf::File::InvalidDataEncoding do
      elf = Elf::File.new(TestDir + "invalid_invalidencoding")
      elf.close
    end
  end

  # Test behaviour when a file with an unsupported ELF version value
  # is opened
  #
  # Expected behaviour: Elf::File::UnsupportedElfVersion exception is
  # raised.
  def test_unsupported_version
    assert(File.exist?(TestDir + "invalid_unsupportedversion"),
           "Missing test file invalid_unsupportedversion")

    assert_raise Elf::File::UnsupportedElfVersion do
      elf = Elf::File.new(TestDir + "invalid_unsupportedversion")
      elf.close
    end
  end

  # Test behaviour when a file with an invalid ELF ABI value is opened
  #
  # Expected behaviour: Elf::File::InvalidOsAbi exception is raised.
  def test_invalid_abi
    assert(File.exist?(TestDir + "invalid_invalidabi"),
           "Missing test file invalid_invalidabi")

    assert_raise Elf::File::InvalidOsAbi do
      elf = Elf::File.new(TestDir + "invalid_invalidabi")
      elf.close
    end
  end

  # Test behaviour when a file with an invalid ELF Type value is
  # opened
  #
  # Expected behaviour: Elf::File::InvalidElfType exception is raised.
  def test_invalid_type
    assert(File.exist?(TestDir + "invalid_invalidtype"),
           "Missing test file invalid_invalidtype")

    assert_raise Elf::File::InvalidElfType do
      elf = Elf::File.new(TestDir + "invalid_invalidtype")
      elf.close
    end
  end

  # Test behaviour when a file with an invalid ELF machine value is
  # opened
  #
  # Expected behaviour: Elf::File::InvalidMachine exception is raised.
  def test_invalid_machine
    assert(File.exist?(TestDir + "invalid_invalidmachine"),
           "Missing test file invalid_invalidmachine")

    assert_raise Elf::File::InvalidMachine do
      elf = Elf::File.new(TestDir + "invalid_invalidmachine")
      elf.close
    end
  end

  # Test behaviour when a file contains an invalid section type
  # (unknown and outside specific ranges).
  #
  # Expected behaviour: Elf::Section::UnknownType exception is raised
  def test_unknown_section_type
    assert(File.exist?(TestDir + "invalid_unknown_section_type"),
           "Missing test file invalid_unknown_section_type")

    begin
      elf = Elf::File.new(TestDir + "invalid_unknown_section_type")
      elf[11] # We need an explicit request for the corrupted section
      elf.close
    rescue Elf::Section::UnknownType => e
      assert_equal(0x0000ff02, e.type_id,
                   "Wrong type_id reported for unknown section type")

      # We expect an integer as the test file will stop processing
      # _before_ strtab is identified, so there is no string table.
      assert_instance_of(Fixnum, e.section_name,
                         "Non-integer section name provided")
      assert_equal(1, e.section_name,
                   "Wrong section_name reported for unknown section type")
      return
    end
    
    flunk("Elf::Section::UnknownType exception not received.")
  end
end
