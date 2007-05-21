# Simple ELF parser for Ruby
#
# Copyright 2007 Diego Pettenò <flameeyes@gmail.com>
# Portions inspired by elf.py
#   Copyright 2002 Netgraft Corporation
# Portions inspired by elf.h
#   Copyright 1995-2006 Free Software Foundation, Inc.
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

require 'bytestream-reader'

# We need this quite e lot
class Integer
  def hex
    sprintf "%x", self
  end
end

class Elf
  class Value
    class OutOfBound < Exception
      def initialize(val)
        @val = val
      end

      def message
        "Value #{@val} out of bound"
      end
    end

    def initialize(val, params)
      @val = val
      @desc = params[1]
    end

    attr_reader :desc, :val
    alias :to_i :val
    alias :to_s :desc

    def ==(other)
      @val == other.to_i and self.class == other.class
    end

    def Value.[](idx)
      raise OutOfBound.new(idx) unless @enums[idx]

      @enums[idx]
    end

    def Value.fill(hash)
      @enums = { }

      hash.each_pair do |index, value|
        @enums[index] = self.new(index, value)
        const_set(value[0], @enums[index])
      end
    end
  end

  MagicString = "\177ELF"

  class Indexes < Value
    fill({
           4 => [ :Class, 'File class' ],
           5 => [ :DataEncoding, 'Data encoding' ],
           6 => [ :Version, 'File version' ],
           7 => [ :OsAbi, 'OS ABI identification' ],
           8 => [ :AbiVersion, 'ABI version' ]
         })
  end

  class Class < Value
    fill({
           1 => [ :Elf32, '32-bit' ],
           2 => [ :Elf64, '64-bit' ]
         })
  end

  class DataEncoding < Value
    fill({
           1 => [ :Lsb, 'Little-endian' ],
           2 => [ :Msb, 'Big-endian' ]
         })

    BytestreamMapping = {
      Lsb => BytestreamReader::LittleEndian,
      Msb => BytestreamReader::BigEndian
    }
  end
  
  class OsAbi < Value
    fill({
             0 => [ :SysV, 'UNIX System V ABI' ],
             1 => [ :HPUX, 'HP-UX' ],
             2 => [ :NetBSD, 'NetBSD' ],
             3 => [ :Linux, 'Linux' ],
             6 => [ :Solaris, 'Solaris' ],
             7 => [ :Aix, 'IBM AIX' ],
             8 => [ :Irix, 'SGI Irix' ],
             9 => [ :FreeBSD, 'FreeBSD' ],
            10 => [ :Tru64, 'Compaq TRU64 UNIX' ],
            11 => [ :Modesto, 'Novell Modesto' ],
            12 => [ :OpenBSD, 'OpenBSD' ],
            97 => [ :ARM, 'ARM' ],
           255 => [ :Standalone, 'Standalone (embedded) application' ]
         })
  end

  class Machine < Value
    fill({
           0 => [ :None, 'No machine' ],
           1 => [ :M32, 'AT&T WE 32100' ],
           2 => [ :Sparc, 'SUN SPARC' ],
           3 => [ :I386, 'Intel 80386' ],
           4 => [ :M68k, 'Motorola m68k family' ],
           5 => [ :M88k, 'Motorola m88k family' ],
           7 => [ :M860, 'Intel 80860' ],
           8 => [ :Mips, 'MIPS R3000 big-endian' ],
           9 => [ :S370, 'IBM System/370' ],
           10 => [ :MipsRS3LE, 'MIPS R3000 little-endian' ],

           15 => [ :PaRisc, 'HPPA' ],
           17 => [ :Vpp500, 'Fujitsu VPP500' ],
           18 => [ :Sparc32Plus, 'Sun\'s "v8plus"' ],
           19 => [ :I960, 'Intel 80960' ],
           20 => [ :PPC, 'PowerPC' ],
           21 => [ :PPC64, 'PowerPC 64-bit' ],
           22 => [ :S390, 'IBM S390' ],

           36 => [ :V800, 'NEC V800 series' ],
           37 => [ :FR20, 'Fujitsu FR20' ],
           38 => [ :RH32, 'TRW RH-32' ],
           39 => [ :RCE, 'Motorola RCE' ],
           40 => [ :ARM, 'ARM' ],
           41 => [ :FakeAlpha, 'Digital Alpha' ],
           42 => [ :SH, 'Hitachi SH' ],
           43 => [ :SparcV9, 'SPARC v9 64-bit' ],
           44 => [ :Tricore, 'Siemens Tricore' ],
           45 => [ :ARC, 'Argonaut RISC Core' ],
           46 => [ :H8300, 'Hitachi H8/300' ],
           47 => [ :H8300H, 'Hitachi H8/300H' ],
           48 => [ :H8S, 'Hitachi H8S' ],
           49 => [ :H8500, 'Hitachi H8/500' ],
           50 => [ :IA64, 'Intel Merced' ],
           51 => [ :MIPSX, 'Stanford MIPS-X' ],
           52 => [ :Coldfire, 'Motorola Coldfire' ],
           53 => [ :M68HC12, 'Motorola M68HC12' ],
           54 => [ :MMA, 'Fujitsu MMA Multimedia Accelerator' ],
           55 => [ :PCP, 'Siemens PCP' ],
           56 => [ :NCPU, 'Sony nCPU embeeded RISC' ],
           57 => [ :NDR1, 'Denso NDR1 microprocessor' ],
           58 => [ :StarCore, 'Motorola Start*Core processor' ],
           59 => [ :ME16, 'Toyota ME16 processor' ],
           60 => [ :ST100, 'STMicroelectronic ST100 processor' ],
           61 => [ :Tinyj, 'Advanced Logic Corp. Tinyj emb.fam' ],
           62 => [ :X8664, 'AMD x86-64 architecture' ],
           63 => [ :PDSP, 'Sony DSP Processor' ],

           66 => [ :FX66, 'Siemens FX66 microcontroller' ],
           67 => [ :ST9Plus, 'STMicroelectronics ST9+ 8/16 mc' ],
           68 => [ :ST7, 'STmicroelectronics ST7 8 bit mc' ],
           69 => [ :M68HC16, 'Motorola MC68HC16 microcontroller' ],
           70 => [ :M68HC11, 'Motorola MC68HC11 microcontroller' ],
           71 => [ :M68HC08, 'Motorola MC68HC08 microcontroller' ],
           72 => [ :M68HC05, 'Motorola MC68HC05 microcontroller' ],
           73 => [ :SVX, 'Silicon Graphics SVx' ],
           74 => [ :ST19, 'STMicroelectronics ST19 8 bit mc' ],
           75 => [ :VAX, 'Digital VAX' ],
           76 => [ :Cris, 'Axis Communications 32-bit embedded processor' ],
           77 => [ :Javelin, 'Infineon Technologies 32-bit embedded processor' ],
           78 => [ :Firepath, 'Element 14 64-bit DSP Processor' ],
           79 => [ :ZSP, 'LSI Logic 16-bit DSP Processor' ],
           80 => [ :MMIX, 'Donald Knuth\'s educational 64-bit processor' ],
           81 => [ :Huany, 'Harvard University machine-independent object files' ],
           82 => [ :Prism, 'SiTera Prism' ],
           83 => [ :AVR, 'Atmel AVR 8-bit microcontroller' ],
           84 => [ :FR30, 'Fujitsu FR30' ],
           85 => [ :D10V, 'Mitsubishi D10V' ],
           86 => [ :D30V, 'Mitsubishi D30V' ],
           87 => [ :V850, 'NEC v850' ],
           88 => [ :M32R, 'Mitsubishi M32R' ],
           89 => [ :MN10300, 'Matsushita MN10300' ],
           90 => [ :MN10200, 'Matsushita MN10200' ],
           91 => [ :PJ, 'picoJava' ],
           92 => [ :OpenRISC, 'OpenRISC 32-bit embedded processor' ],
           93 => [ :ARC_A5, 'ARC Cores Tangent-A5' ],
           94 => [ :Xtensa, 'Tensilica Xtensa Architecture' ],

           0x9026 => [ :Alpha, 'DEC Alpha' ]
         })
  end

  class Symbol
    class Binding < Value
      fill({
              0 => [ :Local, 'Local symbol' ],
              1 => [ :Global, 'Global symbol' ],
              2 => [ :Weak, 'Weak symbol' ],
             # This one is inferred out of libpam.so
              3 => [ :Absolute, 'Absolute symbol' ],
             10 => [ :LoOs, 'OS-specific range start' ],
             12 => [ :HiOs, 'OS-specific range end' ],
             13 => [ :LoProc, 'Processor-specific range start' ],
             15 => [ :HiProc, 'Processor-specific range end' ]
           })
    end

    class Type < Value
      fill({
              0 => [ :None, 'Unspecified' ],
              1 => [ :Object, 'Data object' ],
              2 => [ :Func, 'Code object' ],
              3 => [ :Section, 'Associated with a section' ],
              4 => [ :File, 'File name' ],
              5 => [ :Common, 'Common data object' ],
              6 => [ :TLS, 'Thread-local data object' ],
             10 => [ :LoOs, 'OS-specific range start' ],
             12 => [ :HiOs, 'OS-specific range end' ],
             13 => [ :LoProc, 'Processor-specific range start' ],
             15 => [ :HiProc, 'Processor-specific range end' ]
           })
    end

    attr_reader :value, :size, :other, :bind, :type, :idx

    # Create a new Symbol object reading the symbol structure from the file.
    # This function assumes that the elf file is aligned ad the
    # start of a symbol structure, and returns the file moved at the
    # start of the symbol.
    def initialize(elf, symsect, idx)
      @symsect = symsect
      @idx = idx

      case elf.elf_class
      when Class::Elf32
        @name = elf.read_word
        @value = elf.read_addr
        @size = elf.read_word
        info = elf.read_u8
        @other = elf.read_u8
        @section = elf.read_section
      when Class::Elf64
        @name = elf.read_word
        info = elf.read_u8
        @other = elf.read_u8
        @section = elf.read_section
        @value = elf.read_addr
        @size = elf.read_xword
      end

      @bind = Binding[info >> 4]
      @type = Type[info & 0xF]

      @file = elf
    end

    def name
      # We didn't read the name in form of string yet;
      if @name.is_a? Integer and @symsect.link
        name = @symsect.link[@name]
        @name = name if name
      end

      @name
    end

    def section
      # We didn't read the section yet.
      @section = nil if @section == 0

      if @section.is_a? Integer and @file.sections[@section]
        @section = @file.sections[@section]
      end

      @section
    end

    def version
      return nil if @file.sections['.gnu.version'] == nil or
        section == Elf::Section::Abs or
        ( section.is_a? Elf::Section and section.name == ".bss" )

      version_idx = @file.sections['.gnu.version'][@idx]
      
      return nil unless version_idx >= 2

      return @file.sections['.gnu.version_r'][version_idx][:name] if section == nil

      name_idx = (version_idx & (1 << 15) == 0) ? 0 : 1
      version_idx = version_idx & ~(1 << 15)
      
      return @file.sections['.gnu.version_d'][version_idx][:names][name_idx]
    end
  end

  class File < BytestreamReader
    class NotAnELF < Exception
      def message
        "The file is not an ELF file."
      end
    end

    class Type < Value
      fill({
             0 => [ :None, 'No file type' ],
             1 => [ :Rel, 'Relocatable file' ],
             2 => [ :Exec, 'Executable file' ],
             3 => [ :Dyn, 'Shared object file' ],
             4 => [ :Core, 'Core file' ],
             0xfe00 => [ :LoOs, 'OS-specific range start' ],
             0xfeff => [ :HiOs, 'OS-specific range end' ],
             0xff00 => [ :LoProc, 'Processor-specific range start' ],
             0xffff => [ :HiProc, 'Processor-specific range end' ]
           })
    end

    attr_reader :elf_class, :abi, :machine
    attr_reader :string_table
    attr_reader :sections

    def initialize(path)
      super(path, "rb")

      raise NotAnELF unless readbytes(4) == MagicString

      @elf_class = Class[read_u8]
      @data_encoding = DataEncoding[read_u8]
      @version = read_u8
      @abi = OsAbi[read_u8]
      @abi_version = read_u8

      seek(16, IO::SEEK_SET)
      set_endian(DataEncoding::BytestreamMapping[@data_encoding])

      alias :read_half :read_u16

      alias :read_word :read_u32
      alias :read_sword :read_s32

      alias :read_xword :read_u64
      alias :read_sxword :read_s64

      alias :read_section :read_u16
      alias :read_versym :read_half
      
      case @elf_class
      when Class::Elf32
        alias :read_addr :read_u32
        alias :read_off :read_u32
      when Class::Elf64
        alias :read_addr :read_u64
        alias :read_off :read_u64
      end

      @type = Type[read_half]
      @machine = Machine[read_half]
      @version = read_word
      @entry = read_addr
      @phoff = read_off
      shoff = read_off
      @flags = read_word
      @ehsize = read_half
      @phentsize = read_half
      @phnum = read_half
      @shentsize = read_half
      shnum = read_half
      shstrndx = read_half

      sections = []
      seek(shoff)
      for i in 1..shnum
        sections << Section.read(self)
      end

      @string_table = sections[shstrndx]
      raise Exception unless @string_table.class == StringTable

      @sections = {}
      sections.each_index do |idx|
        @sections[idx] = sections[idx]
        @sections[sections[idx].name] = sections[idx]
      end
    end

    def summary
      $stdout.puts "ELF file #{path}"
      $stdout.puts "ELF class: #{@elf_class} #{@data_encoding} ver. #{@version}"
      $stdout.puts "ELF ABI: #{@abi} ver. #{@abi_version}"
      $stdout.puts "ELF type: #{@type} machine: #{@machine}"
      $stdout.puts "Sections:"
      @sections.values.uniq.each do |sh|
        sh.summary
      end

      return nil
    end
  end

  class Section
    # Reserved sections' indexes
    Undef  = nil    # Would be '0', but this fits enough
    Abs    = 0xfff1 # Absolute symbols
    Common = 0xfff2 # Common symbols

    # Create a new Section object reading the section's header from
    # the file.
    # This function assumes that the elf file is aligned ad the
    # start of a section header, and returns the file moved at the
    # start of the next header.
    def Section.read(elf)
      name = elf.read_word
      type = Type[elf.read_word]

      if Type::Class[type]
        return Type::Class[type].new(elf, name, type)
      else
        return Section.new(elf, name, type)
      end
    end

    attr_reader :offset

    def initialize(elf, name, type)
      elf32 = elf.elf_class == Class::Elf32

      @file = elf
      @name = name
      @type = type
      @flags = elf32 ? elf.read_word : elf.read_xword
      @addr = elf.read_addr
      @offset = elf.read_off
      @size = elf32 ? elf.read_word : elf.read_xword
      @link = elf.read_word
      @info = elf.read_word
      @addralign = elf32 ? elf.read_word : elf.read_xword
      @entsize = elf32 ? elf.read_word : elf.read_xword

      @numentries = @size/@entsize unless @entsize == 0
    end

    def name
      # We didn't read the name in form of string yet;
      # Check if the file has loaded a string table yet
      if @name.is_a? Integer and @file.string_table
        @name = @file.string_table[@name]
      end

      @name
    end

    def link
      # We didn't get the linked section header yet
      if @link.is_a? Integer
        @link = @file.sections[@link]
      end

      @link
    end

    def load
      oldpos = @file.tell
      @file.seek(@offset, IO::SEEK_SET)

      load_internal

      @file.seek(oldpos, IO::SEEK_SET)
    end

    def summary
      $stdout.puts "#{name}\t\t#{@type}\t#{@flags}\t#{@addr}\t#{@offset}\t#{@size}\t#{@link}\t#{@info}\t#{@addralign}\t#{@entsize}"
    end
  end

  class StringTable < Section
    def load_internal
      @rawtable = @file.readbytes(@size)
      
      @table = {}
      idx = 0
      @rawtable.split("\000").each do |string|
        @table[idx] = string ? string : ''

        idx = idx + string.length + 1
      end
    end

    def [](idx)
      load unless @table

      # Sometimes the linker can reduce the table by overloading
      # two names that are substrings
      if not @table[idx]
        @table[idx] = ''

        ptr = idx
        loop do
          break if @rawtable[ptr] == 0
          @table[idx] += @rawtable[ptr, 1]
          ptr += 1
        end
      end

      return @table[idx]
    end

    def debug
      load unless @table

      $stderr.puts @table.inspect
    end
  end

  class SymbolTable < Section
    def load_internal
      @symbols = []
      for i in 1..(@numentries)
        @symbols << Symbol.new(@file, self, i-1)
      end

      return nil
    end

    def symbols
      load unless @symbols

      @symbols
    end
  end

  class Dynamic < Section
    class Type < Value
      attr_reader :attribute

      def initialize(val, params)
        super(val, params)

        @attribute = params[2]
      end

      fill({
              0 => [ :Null, "NULL", :Ignore ],
              1 => [ :Needed, "NEEDED", :Value ],
              2 => [ :PltRelSz, "PLTRELSZ", :Value ],
              3 => [ :PltGot, "PLTGOT", :Ignore ],
              4 => [ :Hash, "HASH", :Address ],
              5 => [ :StrTab, "STRTAB", :Address ],
              6 => [ :SymTab, "SYMTAB", :Address ],
              7 => [ :RelA, "RELA", :Address ],
              8 => [ :RelASz, "RELASZ", :Value ],
              9 => [ :RelAEnt, "RELAENT", :Value ],
             10 => [ :StrSz, "STRSZ", :Value ],
             11 => [ :SymEnt, "SYMENT", :Value ],
             12 => [ :Init, "INIT", :Address ],
             13 => [ :Fini, "FINI", :Address ],
             14 => [ :SoName, "SONAME", :Value ],
             15 => [ :RPath, "RPATH", :Ignore ],
             16 => [ :Symbolic, "SYMBOLIC", :Ignore ],
             17 => [ :Rel, "REL", :Address ],
             18 => [ :RelSz, "RELSZ", :Value ],
             19 => [ :RelEnt, "RELENT", :Value ],
             20 => [ :PltRel, "PLTREL", :Value ],
             21 => [ :Debug, "DEBUG", :Ignore ],
             22 => [ :TextRel, "TEXTREL", :Ignore ],
             23 => [ :JmpRel, "JMPREL", :Address ],
             24 => [ :BindNow, "BINDNOW", :Ignore ],
             25 => [ :InitArray, "INIT_ARRAY", :Address ],
             26 => [ :FiniArray, "FINI_ARRAY", :Address ],
             27 => [ :InitArraySz, "INIT_ARRAYSZ", :Value ],
             28 => [ :FiniArraySz, "FINI_ARRAYSZ", :Value ],
             29 => [ :RunPath, "RUNPATH", :Ignore ],
             30 => [ :Flags, "FLAGS", :Value ],
             32 => [ :PreinitArray, "PREINIT_ARRAY", :Address ],
             33 => [ :PreinitArraySz, "PREINIT_ARRAYSZ", :Value ],

             # DT_VAL* constants mapping
             0x6ffffdf5 => [ :GNUPrelinked, "GNU_PRELINKED", :Value ],
             0x6ffffdf6 => [ :GNUConflictSz, "GNU_CONFLICTSZ", :Value ],
             0x6ffffdf7 => [ :GNULibListSz, "GNU_LIBLISTSZ", :Value ],
             0x6ffffdf8 => [ :CheckSum, "CHECKSUM", :Value ],
             0x6ffffdf9 => [ :PltPadSz, "PLTPADSZ", :Value ],
             0x6ffffdfa => [ :MoveEnt, "MOVENT", :Value ],
             0x6ffffdfb => [ :MoveSz, "MOVESZ", :Value ],
             0x6ffffdfc => [ :Feature1, "FEATURE_1", :Value ],
             0x6ffffdfd => [ :PosFlag1, "POSFLAG_1", :Value ],
             0x6ffffdfe => [ :SymInSz, "SYMINSZ", :Value ],
             0x6ffffdff => [ :SymInEnt, "SYMINENT", :Value ],

             # DT_ADDR* constants mapping
             0x6ffffef5 => [ :GNUHash, "GNU_HASH", :Address ],
             0x6ffffef6 => [ :TLSDescPlt, "TLSDESC_PLT", :Address ],
             0x6ffffef7 => [ :TLSDescGot, "TLSDESC_GOT", :Address ],
             0x6ffffef8 => [ :GNUConflict, "GNU_CONFLICT", :Address ],
             0x6ffffef9 => [ :GNULibList, "GNU_LIBLIST", :Address ],
             0x6ffffefa => [ :Config, "CONFIG", :Address ],
             0x6ffffefb => [ :DepAudit, "DEPAUDIT", :Address ],
             0x6ffffefc => [ :PltPad, "PLTPAD", :Address ],
             0x6ffffefd => [ :MoveTab, "MOVETAB", :Address ],
             0x6ffffeff => [ :SymInfo, "SYMINFO", :Address ],

             # GNU extension, should be named :GNUVerSym?
             0x6ffffff0 => [ :VerSym, "VERSYM", :Ignore ],

             0x6ffffff9 => [ :RelACount, "RELACOUNT", :Value ],
             0x6ffffffa => [ :RelCount, "RELCOUNT", :Value ],
             
             # Sun extensions, should be named :Sun*?
             0x6ffffffb => [ :Flags1, "FLAGS_1", :Value ],
             0x6ffffffc => [ :VerDef, "VERDEF", :Address ],
             0x6ffffffd => [ :VerDefNum, "VERDEFNUM", :Value ],
             0x6ffffffe => [ :VerNeed, "VERNEED", :Address ],
             0x6fffffff => [ :VerNeedNum, "VERNEEDNUM", :Value ]
           })
    end

    def load_internal
      elf32 = @file.elf_class == Class::Elf32

      @entries = []

      for i in 1..@numentries
        entry = {}
        
        type = elf32 ? @file.read_sword : @file.read_sxword
        entry[:type] = Type[ type ]
        entry[:attribute] = case entry[:type]
                            when :Address then @file.read_addr
                            when :Value then elf32 ? @file.read_word : @file.read_xword
                            else @file.read_addr
                            end

        @entries << entry

        break if entry[:type] == Type::Null
      end
    end

    def entries
      load unless @entries

      @entries
    end
  end

  # GNU extensions to the ELF formats.
  # 'nuff said.
  module GNU
    class SymbolVersionUnknown < Exception
      def initialize(val)
        @val = val
      end

      def message
        "GNU Symbol versioning version #{@val} unknown"
      end
    end

    class SymbolVersionTable < Section
      def load_internal
        @versions = []
        for i in 1..(@numentries)
          @versions << @file.read_versym
        end
      end

      def [](idx)
        load unless @versions

        @versions[idx]
      end
    end

    class SymbolVersionDef < Section
      FlagBase = 0x0001
      FlagWeak = 0x0002

      def load_internal
        link.load # do this now for safety

        @defined_versions = {}
        entry_off = @offset
        loop do
          @file.seek(entry_off)

          entry = {}
          version = @file.read_half
          raise SymbolVersionUnknown.new(version) if version != 1
          entry[:flags] = @file.read_half
          ndx = @file.read_half
          aux_count = @file.read_half
          entry[:hash] = @file.read_word
          name_off = entry_off + @file.read_word
          next_entry_off = @file.read_word

          entry[:names] = []
          for i in 1..aux_count
            @file.seek(name_off)
            entry[:names] << link[@file.read_word]
            next_name_off = @file.read_word
            break unless next_name_off != 0
            name_off += next_name_off
          end

          @defined_versions[ndx] = entry

          break unless next_entry_off != 0

          entry_off += next_entry_off
        end
      end
 
      def [](idx)
        load unless @defined_versions

        @defined_versions[idx]
      end
    end

    class SymbolVersionNeed < Section
      def load_internal
        link.load # do this now for safety

        @needed_versions = {}
        loop do
          version = @file.read_half
          raise SymbolVersionUnknown.new(version) if version != 1
          aux_count = @file.read_half
          file = link[@file.read_word]
          # discard the next, it's used for non-sequential reading.
          @file.read_word
          # This one is interesting only when we need to stop the
          # read loop.
          more = @file.read_word != 0

          for i in 1..aux_count
            entry = {}
            
            entry[:file] = file
            entry[:hash] = @file.read_word
            entry[:flags] = @file.read_half

            tmp = @file.read_half # damn Drepper and overloaded values
            entry[:private] = tmp & (1 << 15) == (1 << 15)
            index = tmp & ~(1 << 15)

            entry[:name] = link[@file.read_word]

            @needed_versions[index] = entry

            break unless @file.read_word != 0
          end

          break unless more
        end
      end
 

      def [](idx)
        load unless @needed_versions

        @needed_versions[idx]
      end
    end
  end

  class Section
    class Type < Value
      fill({
              0 => [ :Null, 'Unused' ],
              1 => [ :ProgBits, 'Program data' ],
              2 => [ :SymTab, 'Symbol table' ],
              3 => [ :StrTab, 'String table' ],
              4 => [ :RelA, 'Relocation entries with addends' ],
              5 => [ :Hash, 'Symbol hash table' ],
              6 => [ :Dynamic, 'Dynamic linking information' ],
              7 => [ :Note, 'Notes' ],
              8 => [ :NoBits, 'Program space with no data (bss)' ],
              9 => [ :Rel, 'Relocation entries, no addends' ],
             10 => [ :ShLib, 'Reserved' ],
             11 => [ :DynSym, 'Dynamic linker symbol table' ],
             14 => [ :InitArray, 'Array of constructors' ],
             15 => [ :FiniArray, 'Array of destructors' ],
             16 => [ :PreinitArray, 'Array of pre-constructors' ],
             17 => [ :Group, 'Section group' ],
             18 => [ :SymTabShndx, 'Extended section indeces' ],
#             0x60000000 => [ :LoOs, 'OS-specific range start' ],
             0x6ffffff6 => [ :GnuHash, 'GNU-style hash table' ],
             0x6ffffff7 => [ :GnuLiblist, 'Prelink library list' ],
             0x6ffffff8 => [ :Checksum, 'Checksum for DSO content' ],
#             0x6ffffffa => [ :LoSunW, 'Sun-specific range start' ],
             0x6ffffffa => [ :SunWMove, nil ],
             0x6ffffffb => [ :SunWComDat, nil ],
             0x6ffffffc => [ :SunWSymInfo, nil ],
             0x6ffffffd => [ :GNUVerDef, 'Version definition section' ],
             0x6ffffffe => [ :GNUVerNeed, 'Version needs section' ],
#             0x6fffffff => [ :HiSunW, 'Sun-specific range end' ],
#             0x6fffffff => [ :HiOs, 'OS-specific range end' ],
             0x6fffffff => [ :GNUVerSym, 'Version symbol table' ],
             0x70000000 => [ :LoProc, 'Processor-specific range start' ],
             0x7fffffff => [ :HiProc, 'Processor-specific range end' ],
             0x80000000 => [ :LoUser, 'Application-specific range start' ],
             0x8fffffff => [ :HiUser, 'Application-specific range end' ]
           })

      Class = {
        StrTab => Elf::StringTable,
        SymTab => Elf::SymbolTable,
        DynSym => Elf::SymbolTable,
        Dynamic => Elf::Dynamic,
        GNUVerSym => Elf::GNU::SymbolVersionTable,
        GNUVerDef => Elf::GNU::SymbolVersionDef,
        GNUVerNeed => Elf::GNU::SymbolVersionNeed
      }
    end
  end
end
