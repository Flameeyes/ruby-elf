# -*- coding: utf-8 -*-
# -*- ruby -*-
# Simple ELF parser for Ruby
#
# Copyright © 2010 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

%%{
machine demangle_gcc3;

action mark { mark = p }

operators =
  "ix" % { res << "operator []" } |
  "cl" % { res << "operator ()" } |
  "pt" % { res << "operator ->" } |
  "pp" % { res << "operator ++" } |
  "mm" % { res << "operator --" } |
  "nw" % { res << "operator new" } |
  "na" % { res << "operator new[]" } |
  "dl" % { res << "operator delete" } |
  "da" % { res << "operator delete[]" } |
  "de" % { res << "operator *"} |
  "ad" % { res << "operator &"} |
  "ps" % { res << "operator +"} |
  "ng" % { res << "operator -"} |
  "nt" % { res << "operator !"} |
  "co" % { res << "operator ~"} |
  "pm" % { res << "operator ->*"} |
  "ml" % { res << "operator *"} |
  "dv" % { res << "operator /"} |
  "rm" % { res << "operator %"} |
  "pl" % { res << "operator +"} |
  "mi" % { res << "operator -"} |
  "ls" % { res << "operator <<"} |
  "rs" % { res << "operator >>"} |
  "lt" % { res << "operator <"} |
  "rt" % { res << "operator >"} |
  "le" % { res << "operator <="} |
  "ge" % { res << "operator >="} |
  "eq" % { res << "operator =="} |
  "ne" % { res << "operator !="} |
  "an" % { res << "operator &"} |
  "or" % { res << "operator |"} |
  "eo" % { res << "operator ^"} |
  "aa" % { res << "operator &&" } |
  "oo" % { res << "operator ||" } |
  "aS" % { res << "operator =" } |
  "mL" % { res << "operator *=" } |
  "dV" % { res << "operator /=" } |
  "rM" % { res << "operator %=" } |
  "pL" % { res << "operator +=" } |
  "mI" % { res << "operator -=" } |
  "lS" % { res << "operator <<=" } |
  "rS" % { res << "operator >>=" } |
  "aN" % { res << "operator &=" } |
  "oR" % { res << "operator |=" } |
  "eO" % { res << "operator ^=" } |
  "cm" % { res << "operator ," }
;

std_prefix = "St" % { res << "::std" };

simple_name = (
  [0-9]+ >mark
    %{ 
      len = (data[mark..(p-1)].to_i) -1
      res << "::#{data[p..(p+len)]}"
      p += len
    }
    <: [a-zA-Z_]
);

simple_typename =
  'v' % { typename = 'void' } |
  'b' % { typename = 'bool' } |
  'c' % { typename = 'char' } |
  'a' % { typename = 'signed char' } |
  'h' % { typename = 'unsigned char' } |
  's' % { typename = 'short' } |
  't' % { typename = 'unsigned short' } |
  'i' % { typename = 'int' } |
  'j' % { typename = 'unsigned int' } |
  'l' % { typename = 'long' } |
  'm' % { typename = 'unsigned long' } |
  'x' % { typename = '__int64' } |
  'y' % { typename = 'unsigned __int64' } |
  'w' % { typename = 'wchar_t' } |
  'f' % { typename = 'float' } |
  'd' % { typename = 'double' } |
  'e' % { typename = 'long double' } |
  'Cf' % { typename = '__complex__ float' } |
  'Cd' % { typename = '__complex__ double' } |
  'z' % { typename = '...' }
;

typename = (
            ( 'P' % { suffix = "#{suffix}*" } |
              'R' % { suffix = "#{suffix}&" }
            )? .
            ('V' % { prefix = "volatile #{prefix}" } )?.
            ('K' % { prefix = "const #{prefix}" } )?.
            simple_typename
            )
> { prefix = typename = suffix = '' }
% { typename = "#{prefix}#{typename}#{suffix}" };

parameters_list = ((typename % { params ||= []; params << typename })+)
%{
  params = [] if params == ['void']
  res << "(#{params.join(', ')})"
};

qualified_name = ("N" . ( std_prefix | simple_name ) :> simple_name+ :> "E" :> parameters_list?) |
  (std_prefix :> simple_name) |
  (operators :> parameters_list);

mangled_name := "_Z" . qualified_name;

}%%

module Elf
  class Symbol
    module Demangler
      class GCC3
        %% write data;
        def self.demangle(data)
          res = ""

          %% write init;
          eof = pe;

          %% write exec;

          return nil if cs < demangle_gcc3_first_final

          return res unless res.empty?
          nil
        end
      end
    end
  end
end
