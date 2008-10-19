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
  # Test behaviour when a file is requested that is not present.
  #
  # Expected behaviour: Errno::ENOENT exception is raised
  def test_nofile
    # Check that the file does not exist or we're going to throw an
    # exception to signal an error in the test.
    if File.exists? Elf::TestUnit::TestDir + "invalid_notfound"
      raise Exception.new("A file named 'invalid_notfound' is present in the test directory")
    end

    assert_raise Errno::ENOENT do
      elf = Elf::File.new(Elf::TestUnit::TestDir + "invalid_notfound")
    end
  end

  # Test behaviour when a file that is not an ELF file is opened.
  #
  # Expected behaviour: Elf::File::NotAnElf exception is raised.
  def test_notanelf
    assert_raise Elf::File::NotAnELF do
      elf = Elf::File.new(Elf::TestUnit::TestDir + "invalid_nonelf")
      elf.close
    end
  end

  # Test behaviour when a file too short to be an ELF file is opened
  # (that has not enough data to read the four magic bytes at the
  # start of the file).
  #
  # Expected behaviour: Elf::File::NotAnElf exception is raised.
  def test_shortfile
    assert_raise Elf::File::NotAnELF do
      elf = Elf::File.new(Elf::TestUnit::TestDir + "invalid_shortfile")
      elf.close
    end
  end

  # Test behaviour when a file with an invalid ELF class value is
  # opened
  #
  # Expected behaviour: Elf::File::InvalidElfClass exception is
  # raised.
  def test_invalid_elfclass
    assert_raise Elf::File::InvalidElfClass do
      elf = Elf::File.new(Elf::TestUnit::TestDir + "invalid_invalidclass")
      elf.close
    end
  end

  # Test behaviour when a file with an invalid ELF data encoding value
  # is opened
  #
  # Expected behaviour: Elf::File::InvalidDataEncoding exception is
  # raised.
  def test_invalid_encoding
    assert_raise Elf::File::InvalidDataEncoding do
      elf = Elf::File.new(Elf::TestUnit::TestDir + "invalid_invalidencoding")
      elf.close
    end
  end

  # Test behaviour when a file with an unsupported ELF version value
  # is opened
  #
  # Expected behaviour: Elf::File::UnsupportedElfVersion exception is
  # raised.
  def test_unsupported_version
    assert_raise Elf::File::UnsupportedElfVersion do
      elf = Elf::File.new(Elf::TestUnit::TestDir + "invalid_unsupportedversion")
      elf.close
    end
  end

  # Test behaviour when a file with an invalid ELF ABI value is opened
  #
  # Expected behaviour: Elf::File::InvalidOsAbi exception is raised.
  def test_invalid_abi
    assert_raise Elf::File::InvalidOsAbi do
      elf = Elf::File.new(Elf::TestUnit::TestDir + "invalid_invalidabi")
      elf.close
    end
  end

  # Test behaviour when a file with an invalid ELF Type value is
  # opened
  #
  # Expected behaviour: Elf::File::InvalidElfType exception is raised.
  def test_invalid_type
    assert_raise Elf::File::InvalidElfType do
      elf = Elf::File.new(Elf::TestUnit::TestDir + "invalid_invalidtype")
      elf.close
    end
  end

  # Test behaviour when a file with an invalid ELF machine value is
  # opened
  #
  # Expected behaviour: Elf::File::InvalidMachine exception is raised.
  def test_invalid_machine
    assert_raise Elf::File::InvalidMachine do
      elf = Elf::File.new(Elf::TestUnit::TestDir + "invalid_invalidmachine")
      elf.close
    end
  end

  # Test behaviour when a file contains an invalid section type
  # (unknown and outside specific ranges).
  #
  # Expected behaviour: Elf::Section::UnknownType exception is raised
  def test_unknown_section_type
    begin
      elf = Elf::File.new(Elf::TestUnit::TestDir + "invalid_unknown_section_type")
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

  # Test behaviour when a file lacks a string table and a section is
  # requested by name.
  #
  # Expected behaviour: Elf::File::MissingStringTable exception is
  # raised
  def test_missing_string_table_request
    assert_raise Elf::File::MissingStringTable do
      elf = Elf::File.new(Elf::TestUnit::TestDir + "invalid_unknown_section_type")
      elf[".symtab"]
      elf.close
    end
  end

  # Test behaviour when a file lacks a string table and a section is
  # tested by name.
  #
  # Expected behaviour: Elf::File::MissingStringTable exception is
  # raised
  def test_missing_string_table_test
    assert_raise Elf::File::MissingStringTable do
      elf = Elf::File.new(Elf::TestUnit::TestDir + "invalid_unknown_section_type")
      elf.has_section?(".symtab")
      elf.close
    end
  end

  # Test behaviour when a section is requested in a file that does not
  # have it.
  #
  # Expected behaviour: Elf::Section::MissingSection exception is raised
  def test_missing_section
    elf = Elf::File.new(Elf::TestUnit::TestDir + "arm-crtn.o")

    # Make sure that the has_section? function behaves correctly and
    # _don't_ throw an exception.
    assert(!elf.has_section?(".symtab"),
           ".symtab section present in arm-crtn.o (?!?)")

    assert_raise Elf::File::MissingSection do
      elf[".symtab"]
    end

    elf.close
  end

  # Test behaviour when a section is requested by index, in a file
  # that does not have such an indexed section.
  #
  # Expected behaviour: Elf::Section:MissingSection exception is
  # raised
  def test_missing_section_index
    elf = Elf::File.new(Elf::TestUnit::TestDir + "arm-crtn.o")

    assert_raise Elf::File::MissingSection do
      elf[12300]
    end

    elf.close
  end

  # Test behaviour when trying to check for presence of a section
  # through an invalid type.
  #
  # Expected behaviour: TypeError exception is raised
  def test_has_section_invalid_argument
    elf = Elf::File.new(Elf::TestUnit::TestDir + "arm-crtn.o")

    assert_raise TypeError do
      elf.has_section?({:a => :b})
    end

    elf.close
  end

  # Test behaviour when comparing a section instance with something
  # that is not a section.
  #
  # Expected behaviour: TypeError exception is raised
  def test_invalid_section_comparison
    elf = Elf::File.new(Elf::TestUnit::TestDir + "arm-crtn.o")

    assert_raise TypeError do
      elf[".ARM.attributes"] == "Foobar"
    end

    elf.close
  end

end
