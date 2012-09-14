# -*- coding: utf-8 -*-
# Simple ar format parser for Ruby
#
# Copyright © 2012 Diego Elio Pettenò <flameeyes@flameeyes.eu>
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
require 'pathname'
require 'elf/utils/offsettable'
require 'ar/entry'

module Ar
  class File < Elf::Utilities::IOFrontend
    include BytestreamReader

    MagicString = "!<arch>\n"

    class NotAnAR < Exception
      def initialize
        super("not a valid ar file")
      end
    end

    attr_reader :gnu_names

    def initialize(path)
      super

      begin
        begin
          raise NotAnAR unless readexactly(MagicString.size) == MagicString
        rescue EOFError
          raise NotAnAR
        end

        @files = []
        @files_by_name = {}

        begin
          until eof
            file = Entry.new(self)
            case file.name
            when '/'
              @index = file
            when '//'
              @gnu_names = Elf::Utilities::OffsetTable.new(file.content, "\n")
            else
              @files << file
              @files_by_name[file.name] = file
            end
          end
        rescue EOFError
          raise Errno::ENODATA
        end
      rescue ::Exception => e
        close
        raise e
      end
    end

    def [](index_or_name)
      if index_or_name.is_a?(Integer)
        return @files[index_or_name]
      else
        return @files_by_name[index_or_name]
      end
    end

    def files_count
      @files.size
    end

    def each_file(&block)
      @files.each(&block)
    end
  end
end
