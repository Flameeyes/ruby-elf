# -*- coding: utf-8 -*-
# Simple ELF parser for Ruby
#
# Copyright © 2008 Diego Pettenò <flameeyes@gmail.com>
# Portions inspired by elf.py
#   Copyright © 2002 Netgraft Corporation
# Portions inspired by elf.h
#   Copyright © 1995-2006 Free Software Foundation, Inc.
# Constants derived from OpenSolaris elf.h and documentation
#   Copyright © 2007 Sun Microsystems, Inc.
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

module Elf
  # Sun-specific sections parsing
  module SunW

    class Capabilities < Section
      class Tag < Value
        fill({
               0 => [ :Null, nil ],
               1 => [ :HW1, "Hardware capabilities" ],
               2 => [ :SF1, "Software capabilities" ]
             })
      end

      class Software1 < Value
        fill({
               0x0001 => [ :FramePointerKnown, "Frame pointer use is known" ],
               0x0002 => [ :FramePointerUsed, "Frame pointer is used" ]
             })

        # Known capabilities mask
        KnownMask         = 0x003
      end

      module Hardware1
        class Sparc < Value
          fill({
                 0x0001 => [ :Mul32, "Uses 32x32-bit smul/umul" ],
                 0x0002 => [ :Div32, "Uses 32x32-bit sdiv/udiv" ],
                 0x0004 => [ :Fsmuld, "Uses fsmuld instruction" ],
                 0x0008 => [ :V8Plus, "Uses V9 intructins in 32-bit apps" ],
                 0x0010 => [ :Popc, "Uses popc instruction" ],
                 0x0020 => [ :Vis, "Uses VIS instruction set" ],
                 0x0040 => [ :Vis2, "Uses VIS2 instruction set" ],
                 0x0080 => [ :AsiBlkInit, nil ],
                 0x0100 => [ :Fmaf, "Uses Fused Multiply-Add" ],
                 0x0200 => [ :FjFmau, "Uses Fujitsu Unfused Multiply-Add" ],
                 0x0400 => [ :Ima, "Uses Integer Multiply-Add" ]
               })
        end

        class I386 < Value
          fill({
                 0x00000001 => [ :FPU, "Uses x87-style floating point" ],
                 0x00000002 => [ :TSC, "Uses rdtsc instruction" ],
                 0x00000004 => [ :CX8, "Uses cmpxchg8b instruction" ],
                 0x00000008 => [ :SEP, "Uses sysenter/sysexit instructions" ],
                 0x00000010 => [ :AmdSycC, "Uses AMD's syscall/sysret instructions" ],
                 0x00000020 => [ :CMov, "Uses conditional move instructions" ],
                 0x00000040 => [ :MMX, "Uses MMX instruction set" ],
                 0x00000080 => [ :AmdMMX, "Uses AMD's MMX instruction set" ],
                 0x00000100 => [ :Amd3DNow, "Uses AMD's 3DNow! instruction set" ],
                 0x00000200 => [ :Amd3DNowX, "Uses AMD's 3DNow! extended instruction set" ],
                 0x00000400 => [ :FXSR, "Uses fxsave/fxrstor instructions" ],
                 0x00000800 => [ :SSE, "Uses SSE instruction set and registers" ],
                 0x00001000 => [ :SSE2, "Uses SSE2 instruction set and registers" ],
                 0x00002000 => [ :Pause, "Uses pause instruction" ],
                 0x00004000 => [ :SSE3, "Uses SSE3 instruction set and registers" ],
                 0x00008000 => [ :Mon, "Uses monitor/mwait instructions" ],
                 0x00010000 => [ :CX16, "Uses cmpxchg16b instruction" ],
                 0x00020000 => [ :AHF, "Uses lahf/sahf instructions" ],
                 0x00040000 => [ :TSCP, "Uses rdtscp instruction" ],
                 0x00080000 => [ :AmdSSE4a, "Uses AMD's SSEA4a instructions" ],
                 0x00100000 => [ :PopCnt, "Uses popcnt instruction" ],
                 0x00200000 => [ :AmdLzcnt, "Uses AMD's lzcnt instructon" ],
                 0x00400000 => [ :SSSE3, "Uses Intel's SSSE3 instruction set" ],
                 0x00800000 => [ :SSE4_1, "Uses Intel's SSE4.1 instruction set" ],
                 0x01000000 => [ :SSE4_2, "uses Intel's SSE4.2 instruction set" ]
               })
        end
      end

      def load_internal
        elf32 = @file.elf_class == Class::Elf32

        @entries = []
        loop do
          entry = {}
          tag = elf32 ? @file.read_word : @file.read_xword
          entry[:tag] = Tag[tag]

          # This marks the end of the array.
          break if entry[:tag] == Tag::Null

          # Right now the only two types used make only use of c_val,
          # but in the future there might be capabilities using c_ptr,
          # so prepare for that.
          case entry[:tag]
          when Tag::SF1
            val = elf32 ? @file.read_word : @file.read_xword
            entry[:flags] = Set.new
            
            Software1.each do |flag|
              entry[:flags].add(flag) if (val & flag.val) == flag.val
            end
          when Tag::HW1
            val = elf32 ? @file.read_word : @file.read_xword
            entry[:flags] = Set.new

            case @file.machine
            when Machine::Sparc
              Hardware1::Sparc.each do |flag|
                entry[:flags].add(flag) if (val & flag.val) == flag.val
              end
            when Machine::I386
              Hardware1::I386.each do |flag|
                entry[:flags].add(flag) if (val & flag.val) == flag.val
              end
            else
              raise "Sun-specific extensions only support i386/Sparc!"
            end
                
          else
            entry[:ptr] = @file.read_addr
          end

          @entries << entry
        end
      end
      
      def count
        load unless @entries
        
        @entries.size
      end

      def [](idx)
        load unless @entries
        
        @entries[idx]
      end
    end
  end
end
