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

module Elf
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
             15 => [ :RPath, "RPATH", :Value ],
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
             29 => [ :RunPath, "RUNPATH", :Value ],
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

    module Flags
      Origin     = 0x00000001
      Symbolic   = 0x00000002
      Textrel    = 0x00000004
      BindNow    = 0x00000008
      StaticTLS  = 0x00000010
    end

    module Flags1
      Now        = 0x00000001
      Global     = 0x00000002
      Group      = 0x00000004
      NoDelete   = 0x00000008
      LoadFltr   = 0x00000010
      InitFirst  = 0x00000020
      NoOpen     = 0x00000040
      Origin     = 0x00000080
      Direct     = 0x00000100
      Trans      = 0x00000200
      Interpose  = 0x00000400
      NoDefLib   = 0x00000800
      NoDump     = 0x00001000
      ConfAlt    = 0x00002000
      EndFiltee  = 0x00004000
      DispRelDNE = 0x00008000
      DispRelPND = 0x00010000
    end

    module Features1
      ParInit    = 0x00000001
      ConfExp    = 0x00000002
    end

    module PosFlags1
      LazyLoad   = 0x00000001
      GroupPerm  = 0x00000002
    end

    def load_internal
      elf32 = @file.elf_class == Class::Elf32

      @entries = []

      for i in 1..@numentries
        entry = {}
        
        type = elf32 ? @file.read_sword : @file.read_sxword
        entry[:type] = Type[ type ]
        entry[:attribute] = case entry[:type].attribute
                            when :Address then @file.read_addr
                            when :Value then elf32 ? @file.read_word : @file.read_xword
                            else @file.read_addr
                            end

        entry[:parsed] = 
          case entry[:type]
          when Type::Needed, Type::SoName,
            Type::RPath, Type::RunPath

            @file['.dynstr'][entry[:attribute]]
          when Type::GNUPrelinked
            Time.at(entry[:attribute])
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
end
