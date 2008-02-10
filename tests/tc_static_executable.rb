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

require Pathname.new(__FILE__).dirname + 'tests_elf'

# Test proper handling of Static Executable ELF files.
class TC_Static_Executable < Test::Unit::TestCase
  TestBaseFilename = "static_executable"
  TestElfType = Elf::File::Type::Exec
  include ElfTests

  # Test for _not_ of .dynamic section on the file.
  # This is a prerequisite for static executable files.
  def test_staic
    @elfs.each_pair do |name, elf|
      assert(!elf.sections['.dynamic'],
             ".dynamic section present on ELF file #{elf.path}")
    end
  end
end
