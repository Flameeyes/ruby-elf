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

module ElfTests
  TestDir = Pathname.new(__FILE__).dirname + "binaries"
  OSes = [ "linux" ]
  Arches = [ "x86", "amd64" ]
  
  def setup
    @elfs = {}

    # Check for presence of all the executables for the arches to test.
    # Make sure to check all the operating systems too.
    # Also open the ELF files for testing
    OSes.each do |os|
      Arches.each do |arch|
        filename = "#{os}_#{arch}_#{self.class::TestBaseFilename}"
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

  def test_type
    @elfs.each_pair do |name, elf|
      assert(elf.type == self.class::TestElfType)
    end
  end

  def test_elfclass
    @elfs.each_pair do |name, elf|
      expectedclass = case name
                      when /.*_x86/
                        Elf::Class::Elf32
                      when /.*_amd64/
                        Elf::Class::Elf64
                      end

      assert(elf.elf_class == expectedclass,
             "ELF class for #{elf.path} (#{elf.elf_class}) differs from expected class (#{expectedclass})")
    end
  end

  def test_dataencoding
    @elfs.each_pair do |name, elf|
      expectedencoding = case name
                         when /.*_x86/, /.*_amd64/
                           Elf::DataEncoding::Lsb
                         end

      assert(elf.data_encoding == expectedencoding,
             "ELF encoding for #{elf.path} (#{elf.data_encoding}) differs from expected class (#{expectedencoding})")
    end
  end

end
