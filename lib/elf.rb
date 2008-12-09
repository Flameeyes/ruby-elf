# -*- coding: utf-8 -*-
# Simple ELF parser for Ruby
#
# Copyright © 2007 Diego Pettenò <flameeyes@gmail.com>
# Portions inspired by elf.py
#   Copyright © 2002 Netgraft Corporation
# Portions inspired by elf.h
#   Copyright © 1995-2006 Free Software Foundation, Inc.
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

require 'elf/value'
require 'elf/symbol'
require 'elf/file'
require 'elf/section'

# We need this quite e lot
class Integer
  def hex
    sprintf "%x", self
  end
end

module Elf

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

end
