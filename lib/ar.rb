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

module Ar
  class File < ::File
    include BytestreamReader

    MagicString = "!<arch>\n"

    class NotAnAR < Exception
      def initialize
        super("not a valid ar file")
      end
    end

    def _checkvalidpath(path)
      # We're going to check the path we're given for a few reasons,
      # the first of which is that we do not want to open a pipe or
      # something like that. If we were just to leave it to File.open,
      # we would end up stuck waiting for data on a named pipe, for
      # instance.
      #
      # We cannot just use File.file? either because it'll be ignoring
      # ENOENT by default (which would be bad for us).
      #
      # If we were just to use File.ftype we would have to handle
      # manually the links... since Pathname will properly report
      # ENOENT for broken links, we're going to keep it this way.
      path = Pathname.new(path) unless path.is_a? Pathname

      case path.ftype
      when "directory" then raise Errno::EISDIR
      when "file" then # do nothing
      when "link"
        # we use path.realpath here; the reason is that if
        # we're to use readlink we're going to have a lot of
        # trouble to find the correct path. We cannot just
        # always use realpath as that will run too many stat
        # calls and have a huge hit on performance.
        _checkvalidpath(path.realpath)
      else
        raise Errno::EINVAL
      end
    end

    private :_checkvalidpath

    def initialize(path)
      _checkvalidpath(path)

      super(path, "rb")

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
            # read the file header; most of the content is actually in
            # an ASCII-compatible text format, which is very easy to
            # parse
            file = {
              :name => readexactly(16).rstrip,
              :mtime => Time.at(readexactly(12).rstrip.to_i),
              :owner => readexactly(6).rstrip.to_i,
              :group => readexactly(6).rstrip.to_i,
              :mode => readexactly(8).rstrip.to_i(8),
              :size => readexactly(10).rstrip.to_i
            }

            raise NotAnAR if readexactly(2) != "\x60\x0a"

            case file[:name]
            when "/"
              # this is the index that has to be parsed
              seek(file[:size] + (file[:size]%1), IO::SEEK_CUR)
              next
            when "//"
              # this is the extended filename table, just read it and
              # skip adding the file to the list.
              @gnu_names = Elf::Utilities::OffsetTable.new(readexactly(file[:size]), "\n")
            else
              if file[:name][0..2] == "#1/"
                file[:name] = readexactly(file[:name][3..-1].to_i)
              end

              if file[:name][0] == "/"
                file[:name] = @gnu_names[file[:name][1..-1].to_i]
              end
              
              # GNU ar terminates all filenames with a slash; remove it
              # to have the actual filename. Keep / and // the same so
              # that they can keep their defined names.
              file[:name].sub!(/([^\/])\/$/, '\1')

              file[:offset] = tell()

              @files << file
              @files_by_name[file[:name]] = file

              seek(file[:size] + (file[:size]%1), IO::SEEK_CUR)
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
  end
end
