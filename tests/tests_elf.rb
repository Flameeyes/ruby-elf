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
  OS_Arches = [
               "linux_x86",
               "linux_amd64",
               "linux_sparc",
               "linux_arm",
               "bare_h8300",
               "solaris_x86_gcc",
               "solaris_x86_suncc"
              ]
  def setup
    @elfs = {}

    # Check for presence of all the executables for the arches to test.
    # Make sure to check all the operating systems too.
    # Also open the ELF files for testing
    OS_Arches.each do |os_arch|
      basefilename = self.class::TestBaseFilename

      case os_arch

      # We obviously cannot test dynamic executables for bare hardware
      # targets
      when /^bare_/
        next if basefilename == "dynamic_executable"
        basefilename = "static_executable.o" if basefilename == "dynamic_executable.o"
        
      # For some reasons building static executables on OpenSolaris
      # does not look possible (misisng libc archive), thus just use
      # executable for the filename.
      when /^solaris_/
        case basefilename
        when "static_executable": next
        when "dynamic_executable": basefilename = "executable"
        when "dynamic_executable.o": basefilename = "executable.o"
        end
      end

      filename = "#{os_arch}_#{basefilename}"
      assert(File.exists?( TestDir + filename ),
             "Missing test file #{filename}")
      @elfs["#{os_arch}"] = Elf::File.open(TestDir + filename)
    end
  end
  
  def teardown
    @elfs.each_pair do |name, elf|
      elf.close
    end
  end

  # We assume that all the ELF files we test are ELF 1 files.
  def test_version
    @elfs.each_pair do |name, elf|
      assert(elf.version == 1,
             "ELF version for #{elf.path} (#{elf.version}) differs from expected version (1)")
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
                      when /.*_x86/, /.*_arm/, /linux_sparc/, /.*_h8300/
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
                         when /.*_x86/, /.*_amd64/, /.*_arm/
                           Elf::DataEncoding::Lsb
                         when /.*_sparc/, /.*_h8300/
                           Elf::DataEncoding::Msb
                         end

      assert(elf.data_encoding == expectedencoding,
             "ELF encoding for #{elf.path} (#{elf.data_encoding}) differs from expected encoding (#{expectedencoding})")
    end
  end

  def test_abi
    @elfs.each_pair do |name, elf|
      expectedabi = case name
                    when /linux_arm/
                      Elf::OsAbi::ARM
                    when /linux_.*/, /bare_.*/, /solaris_.*/
                      Elf::OsAbi::SysV
                    end
      expectedabiversion = case name
                           when /linux_.*/, /bare_.*/, /solaris_.*/
                             0
                           end

      assert(elf.abi == expectedabi,
             "ELF ABI for #{elf.path} (#{elf.abi}) differs from expected ABI (#{expectedabi})")
      assert(elf.abi_version == expectedabiversion,
             "ELF ABI version for #{elf.path} (#{elf.abi_version}) differs from expected ABI version (#{expectedabiversion})")
    end
  end

  def test_machine
    @elfs.each_pair do |name, elf|
      expectedmachine = case name
                        when /.*_x86/
                          Elf::Machine::I386
                        when /.*_amd64/
                          Elf::Machine::X8664
                        when /.*_arm/
                          Elf::Machine::ARM
                        when /.*_sparc/
                          case elf.type
                          when Elf::File::Type::Rel then Elf::Machine::Sparc
                          when Elf::File::Type::Exec then Elf::Machine::Sparc32Plus
                          end
                        when /.*_h8300/
                          Elf::Machine::H8300
                        end

      assert(elf.machine == expectedmachine,
             "ELF machine for #{elf.path} (#{elf.machine}) differs from expected amchine (#{expectedmachine})")
    end
  end

  # Test section flags handling.
  #
  # For each file make sure that .text has at least some flags
  # enabled, like ExecInstr and Alloc.
  def test_text_flags
    @elfs.each_pair do |name, elf|
      assert(elf.sections['.text'],
             "ELF file #{elf.path} does not contain .text section")
      assert(elf.sections['.text'].flags.include?(Elf::Section::Flags::ExecInstr),
             "ELF file #{elf.path}'s .text section is not executable")
      assert(elf.sections['.text'].flags.include?(Elf::Section::Flags::Alloc),
             "ELF file #{elf.path}'s .text section is not allocated")
    end
  end

end
