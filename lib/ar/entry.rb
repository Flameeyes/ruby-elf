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

require 'ar'

module Ar
  class Entry 
    attr_reader :name, :mtime, :owner, :group, :mode, :size

    def initialize(archive)
      raise ArgumentError.new unless archive.is_a?(Ar::File)

      @backend = archive

      # read the file header; most of the content is actually in an
      # ASCII-compatible text format, which is very easy to parse
      @name = @backend.readexactly(16).rstrip
      @mtime = Time.at(@backend.readexactly(12).rstrip.to_i)
      @owner = @backend.readexactly(6).rstrip.to_i
      @group = @backend.readexactly(6).rstrip.to_i
      @mode = @backend.readexactly(8).rstrip.to_i(8)
      @size = @backend.readexactly(10).rstrip.to_i
      
      raise File::NotAnAR if @backend.readexactly(2) != "\x60\x0a"

      if @name[0..2] == "#1/"
        bsd_name_length = @name[3..-1].to_i

        @name = @backend.readexactly(bsd_name_length)
        @size -= bsd_name_length

        # for whatever reason the ar(1) command provided by
        # Apple in Mac OS X (10.8) seems to get the size
        # wrong, and pads the filename with zero bytes.
        @name.sub!(/\0+$/, '');
      end

      if @name =~ /^\/\d+$/
        @name = @backend.gnu_names[@name[1..-1].to_i]
      end
      
      # GNU ar terminates all filenames with a slash; remove it
      # to have the actual filename. Keep / and // the same so
      # that they can keep their defined names.
      @name.sub!(/([^\/])\/$/, '\1')

      @offset = @backend.tell()
      @fpos = 0

      @backend.seek(@size, IO::SEEK_CUR)
    end

    def content
      oldpos = @backend.tell()
      @backend.seek(@offset, IO::SEEK_SET)

      @backend.readexactly(@size)
    ensure
      @backend.seek(oldpos, IO::SEEK_SET)
    end

    def read(rsize)
      return nil if @fpos >= @size

      rsize = rsize.to_i
      rsize = (@size - @fpos) if (@fpos + rsize) >= @size

      oldpos = @backend.tell()
      @backend.seek(@offset+@fpos, IO::SEEK_SET)

      @backend.read(rsize)
    ensure
      @fpos += rsize unless rsize.nil?
      @backend.seek(oldpos, IO::SEEK_SET) unless oldpos.nil?
    end

    def readpartial(rsize)
      raise EOFError.new if @fpos >= @size

      rsize = rsize.to_i
      rsize = (@size - @fpos) if (@fpos + rsize) >= @size

      oldpos = @backend.tell()
      @backend.seek(@offset+@fpos, IO::SEEK_SET)

      @backend.readpartial(rsize)
    ensure
      @fpos += rsize unless rsize.nil?
      @backend.seek(oldpos, IO::SEEK_SET) unless oldpos.nil?
    end

    def eof
      @fpos >= @size
    end

    def tell
      @fpos
    end

    def seek(pos, direction = IO::SEEK_SET)
      @fpos = case direction
              when IO::SEEK_SET then pos
              when IO::SEEK_CUR then (@fpos + pos)
              when IO::SEEK_END then (@size - pos)
              end
      0 # for compatibility with IO#seek
    end

    # this is a moot function to make it look like an IO object.
    def close
    end
  end
end
