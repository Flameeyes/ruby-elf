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

class TC_Executable < Test::Unit::TestCase
  TestDir = Pathname.new(__FILE__).dirname + "binaries"

  def setup
    @elfs = {}

    # Check for presence of all the executables for the arches to test.
    # Make sure to check all the operating systems too.
    # Also open the ELF files for testing
    [ "linux" ].each do |os|
      [ "x86", "amd64" ].each do |arch|
        filename = "#{os}_#{arch}_executable"
        assert(File.exists?( TestDir + filename ),
               "Missing test file #{filename}")
        @elfs["#{os}_#{arch}"] = Elf::File.open(TestDir + filename)
      end
    end
  end

  def teardown
    @elfs.each_pair do |name, elf|
      elf.close
    end
  end

  def test_elfclass
    assert(@elfs['linux_x86'].elf_class == Elf::Class::Elf32)
    assert(@elfs['linux_amd64'].elf_class == Elf::Class::Elf64)
  end

end
