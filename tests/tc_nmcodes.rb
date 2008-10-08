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

# Tests for nm(1)-style codes support in Ruby-Elf
#
# This test will load the file built from the symboltypes.c source
# file and will ensure that the symbols in there reports the correct
# nm(1)-style code.
#
# Right now only Linux/AMD64 version of the file is tested
class TC_NM_Codes < Elf::TestUnit
  def test_symtab
    assert(@elf.has_section?(".symtab"),
           "ELF file #{filename} lacks symbol table!")
  end

  def dotest_symbols(table)
    table.each_pair do |sym, code|
      assert_equal code, @elf[".symtab"][sym].nm_code, "Testing #{sym}"
    end
  end

  # Test the general symbols
  def test_general
    dotest_symbols({ "symboltypes.c" => 'a'})
  end

  # Test variables
  def test_variables
    dotest_symbols({ "external_variable"               => 'D',
                     "static_variable"                 => 'd',
                     "relocated_external_variable"     => 'D',
                     "relocated_static_variable"       => 'd',
                     "external_uninitialised_variable" => 'C',
                     "static_uninitialised_variable"   => 'b' })
  end

  # Test TLS variables
  def test_tls
    dotest_symbols({ "external_tls_variable"               => 'D',
                     "static_tls_variable"                 => 'd',
                     "external_uninitialised_tls_variable" => 'B',
                     "static_uninitialised_tls_variable"   => 'b',
                     "relocated_external_tls_variable"     => 'D',
                     "relocated_static_tls_variable"       => 'd' })
  end

  # Test constants
  def test_constants
    dotest_symbols({ "external_constant"           => 'R',
                     "static_constant"             => 'r',
                     "relocated_external_constant" => 'D',
                     "relocated_static_constant"   => 'd' })
  end

  # Test functions
  def test_functions
    dotest_symbols({ "external_function"      => 'T',
                     "static_function"        => 't',
                     "external_cold_function" => 'T',
                     "static_cold_function"   => 't',
                     "external_hot_function"  => 'T',
                     "static_hot_function"    => 't' })
  end

  # Test section names symbols
  #
  # Each section in an ELF file has its equivalent symbol name, test
  # the presence of (some) section names in symbols and their value
  #
  # TODO: these symbols don't appear to be loaded by ruby-elf!
  # def test_sections
  #   dotest_symbols({ ".bss"               => 'b',
  #                    ".comment"           => 'n',
  #                    ".data"              => 'd',
  #                    ".data.rel.local"    => 'd',
  #                    ".data.rel.ro.local" => 'd',
  #                    ".eh_frame"          => 'r',
  #                    ".note.GNU-stack"    => 'n',
  #                    ".rodata"            => 'r',
  #                    ".tss"               => 'b',
  #                    ".tdata"             => 'd',
  #                    ".text"              => 't' })
  # end

  class LinuxAMD64 < TC_NM_Codes
    Filename = "linux_amd64_symboltypes.o"
  end

  def self.subsuite
    suite = Test::Unit::TestSuite.new
    suite << LinuxAMD64.suite
  end
end
