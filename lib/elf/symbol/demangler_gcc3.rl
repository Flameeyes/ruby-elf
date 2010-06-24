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

simple_typename = ( 'v' % { typename = 'void' } |
                    'i' % { typename = 'int' } |
                    'b' % { typename = 'bool' } );

typename = ( simple_typename |
              ('P' . simple_typename) % { typename << "*" }
            );

parameters_list = ((typename % { params << typename })*)
> { params = [] };

returnval = typename % { res = "#{typename} #{res}(#{params.join(', ')})" };

qualified_name = ("N" . ( std_prefix | simple_name ) :> simple_name+ :> parameters_list :> "E" :> returnval?) |
  (std_prefix :> simple_name);

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
