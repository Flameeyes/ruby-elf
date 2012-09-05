# -*- coding: utf-8 -*-
# Offset-based string table
#
# Copyright © 2007-2012 Diego Elio Pettenò <flameeyes@flameeyes.eu>
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
  module Utilities
    class OffsetTable
      class InvalidIndex < Exception
        def initialize(idx, max_idx)
          super("Invalid index #{idx} (maximum index: #{max_idx})")
        end
      end

      def initialize(content, separator)
        @content = content
        @separator = separator
      end

      def size
        @content.size
      end

      def [](idx)
        raise InvalidIndex.new(idx, size) if idx >= size

        # find the first occurrence of the separator starting from the
        # given index
        endidx = @content.index(@separator, idx)

        return @content[idx..endidx].chomp(@separator)
      end
    end
  end
end
