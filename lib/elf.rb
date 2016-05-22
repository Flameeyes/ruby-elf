# -*- coding: utf-8 -*-
# Simple ELF parser for Ruby
#
# Copyright © 2007-2010 Diego Elio Pettenò <flameeyes@flameeyes.eu>
# Portions inspired by elf.py
#   Copyright © 2002 Netgraft Corporation
# Portions inspired by glibc's elf.h
#   Copyright © 1995-2006 Free Software Foundation, Inc.
# Portions inspired by GNU Binutils's elf/common.h
#   Copyright © 1991-2009 Free Software Foundation, Inc.
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

module Elf
  VERSION = "1.0.8"

  MagicString = "\177ELF"

  class Indexes < Value
    fill(
           4 => [ :Class, 'File class' ],
           5 => [ :DataEncoding, 'Data encoding' ],
           6 => [ :Version, 'File version' ],
           7 => [ :OsAbi, 'OS ABI identification' ],
           8 => [ :AbiVersion, 'ABI version' ]
         )
  end

  class Class < Value
    fill(
           1 => [ :Elf32, '32-bit' ],
           2 => [ :Elf64, '64-bit' ]
         )
  end

  class DataEncoding < Value
    fill(
           1 => [ :Lsb, 'Little-endian' ],
           2 => [ :Msb, 'Big-endian' ]
         )

    BytestreamMapping = {
      Lsb => BytestreamReader::LittleEndian,
      Msb => BytestreamReader::BigEndian
    }
  end
  
  class OsAbi < Value
    fill(
             0 => [ :SysV, 'UNIX - System V' ],
             1 => [ :HPUX, 'HP-UX' ],
             2 => [ :NetBSD, 'NetBSD' ],
             3 => [ :Linux, 'Linux' ],
             4 => [ :Hurd, 'Hurd' ],
             6 => [ :Solaris, 'Solaris' ],
             7 => [ :Aix, 'IBM AIX' ],
             8 => [ :Irix, 'SGI Irix' ],
             9 => [ :FreeBSD, 'FreeBSD' ],
            10 => [ :Tru64, 'Compaq TRU64 UNIX' ],
            11 => [ :Modesto, 'Novell Modesto' ],
            12 => [ :OpenBSD, 'OpenBSD' ],
            13 => [ :OpenVMS, 'OpenVMS' ],
            14 => [ :NSK, 'Hewlett-Packard Non-Stop Kernel' ],
            15 => [ :AROS, 'AROS' ],
            16 => [ :FenixOS, 'FenixOS' ],
            97 => [ :ARM, 'ARM' ],
           255 => [ :Standalone, 'Standalone (embedded) application' ]
         )

    def linux_compatible?;
      [Elf::OsAbi::SysV, Elf::OsAbi::Linux].include?(self)
    end
  end

  class Machine < Value
    fill(
             0 => [ :None, 'No machine' ],
             1 => [ :M32, 'AT&T WE 32100' ],
             2 => [ :Sparc, 'SUN SPARC' ],
             3 => [ :I386, 'Intel 80386' ],
             4 => [ :M68k, 'Motorola m68k family' ],
             5 => [ :M88k, 'Motorola m88k family' ],
             6 => [ :I486, 'Intel 80486 (reserved)' ],
             7 => [ :I860, 'Intel 80860' ],
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
            23 => [ :SPU, 'Sony/Toshiba/IBM SPU' ],

            36 => [ :V800, 'NEC V800 series' ],
            37 => [ :FR20, 'Fujitsu FR20' ],
            38 => [ :RH32, 'TRW RH-32' ],
            39 => [ :RCE, 'Motorola RCE' ],
            40 => [ :ARM, 'ARM' ],

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
            62 => [ :X8664, 'AMD x86-64' ],
            63 => [ :PDSP, 'Sony DSP Processor' ],
            64 => [ :PDP10, 'DEC PDP-10' ],
            65 => [ :PDP11, 'DEC PDP-11' ],
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
            95 => [ :VideoCore, 'Alphamosaic VideoCore processor' ],
            96 => [ :TMM_GPP, 'Thompson Multimedia General Purpose Processor' ],
            97 => [ :NS32K, 'National Semiconductor 32000 series' ],
            98 => [ :TPC, 'Tenor Network TPC processor' ],
            99 => [ :SNP1K, 'Trebia SNP 1000 processor' ],
           100 => [ :ST200, 'STMicroelectronics ST200 microcontroller' ],
           101 => [ :IP2K, 'Ubicom IP2022 micro controller' ],
           102 => [ :MAX, 'MAX Processor' ],
           103 => [ :CR, 'National Semiconductor CompactRISC' ],
           104 => [ :F2MC16, 'Fujitsu F2MC16' ],
           105 => [ :MSP430, 'TI msp430 micro controller' ],
           106 => [ :Blackfin, 'ADI Blackfin' ],
           107 => [ :SE_C33, 'S1C33 Family of Seiko Epson processors' ],
           108 => [ :SEP, 'Sharp embedded microprocessor' ],
           109 => [ :ARCA, 'Arca RISC Microprocessor' ],
           110 => [ :UNICORE, 'Microprocessor series from PKU-Unity Ltd. and MPRC of Peking University' ],
           111 => [ :EXCESS, 'eXcess: 16/32/64-bit configurable embedded CPU' ],
           112 => [ :DXP, 'Icera Semiconductor Inc. Deep Execution Processor' ],
           113 => [ :Altera_Nios2, 'Altera Nios II soft-core processor' ],
           114 => [ :CRX, 'National Semiconductor CRX' ],
           115 => [ :XGATE, 'Motorola XGATE embedded processor' ],
           116 => [ :C166, 'Infineon C16x/XC16x processor' ],
           117 => [ :M16C, 'Renesas M16C series microprocessors' ],
           118 => [ :DSPIC30F, 'Microchip Technology dsPIC30F Digital Signal Controller' ],
           119 => [ :CE, 'Freescale Communication Engine RISC core' ],
           120 => [ :M32C, 'Renesas M32C series microprocessors' ],
           131 => [ :TSK3000, 'Altium TSK3000 core' ],
           132 => [ :RS08, 'Freescale RS08 embedded processor' ],
           134 => [ :ECOG2, 'Cyan Technology eCOG2 microprocessor' ],
           135 => [ :Score7, 'Sunplus S+core7 RISC processor' ],
           136 => [ :DSP24, 'New Japan Radio (NJR) 24-bit DSP Processor' ],
           137 => [ :VideoCore3, 'Broadcom VideoCore III processor' ],
           138 => [ :LatticeMICO32, 'RISC processor for Lattice FPGA architecture' ],
           139 => [ :SE_C17, 'Seiko Epson C17 family' ],
           140 => [ :TI_C6000, 'Texas Instruments TMS320C6000 DSP family' ],
           141 => [ :TI_C2000, 'Texas Instruments TMS320C2000 DSP family' ],
           142 => [ :TI_C5500, 'Texas Instruments TMS320C55x DSP family' ],
           160 => [ :MMDSP_PLUS, 'STMicroelectronics 64bit VLIW Data Signal Processor' ],
           161 => [ :Cypress_M8C, 'Cypress M8C microprocessor' ],
           162 => [ :R32C, 'Renesas R32C series microprocessors' ],
           163 => [ :TriMedia, 'NXP Semiconductors TriMedia architecture family' ],
           164 => [ :QDSP6, 'QUALCOMM DSP6 Processor' ],
           165 => [ :I8051, 'Intel 8051 and variants' ],
           166 => [ :STXP7X, 'STMicroelectronics STxP7x family' ],
           167 => [ :NDS32, 'Andes Technology compact code size embedded RISC processor family' ],
           168 => [ :ECOG1X, 'Cyan Technology eCOG1X family' ],
           169 => [ :MAXQ30, 'Dallas Semiconductor MAXQ30 Core Micro-controllers' ],
           170 => [ :XIMO16, 'New Japan Radio (NJR) 16-bit DSP Processor' ],
           171 => [ :MANIK, 'M2000 Reconfigurable RISC Microprocessor' ],
           172 => [ :CRAYNV2, 'Cray Inc. NV2 vector architecture' ],
           173 => [ :RX, 'Renesas RX family' ],
           174 => [ :METAG, 'Imagination Technologies META processor architecture' ],
           175 => [ :MCST_ELBRUS, 'MCST Elbrus general purpose hardware architecture' ],
           176 => [ :ECOG16, 'Cyan Technology eCOG16 family' ],
           177 => [ :CR16, 'National Semiconductor CompactRISC 16-bit processor' ],
           178 => [ :ETPU, 'Freescale Extended Time Processing Unit' ],
           179 => [ :SLE9X, 'Infineon Technologies SLE9X core' ],
           180 => [ :L1OM, 'Intel L1OM' ],
           183 => [ :AArch64, 'ARM AARCH64 (ARM64)' ],
           185 => [ :AVR32, 'Atmel Corporation 32-bit microprocessor family' ],
           186 => [ :STM8, 'STMicroeletronics STM8 8-bit microcontroller' ],
           187 => [ :TILE64, 'Tilera TILE64 multicore architecture family' ],
           188 => [ :TILEPro, 'Tilera TILEPro multicore architecture family' ],
           189 => [ :MicroBlaze, 'Xilinx MicroBlaze 32-bit RISC soft processor core' ],
           190 => [ :CUDA, 'NVIDIA CUDA architecture' ],
           191 => [ :TILEGx, 'Tilera TILE-Gx' ],

           0x9026 => [ :Alpha, 'DEC Alpha' ]
         )
    Score = Score7
    ECOG1 = ECOG1X
  end

end
