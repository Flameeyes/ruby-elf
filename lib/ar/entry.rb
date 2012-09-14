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

    # this is different from the one in iofrontend because we don't
    # use super, we go straight to the backend, which we know being an
    # Ar::File object.
    def method_missing(meth, *args, &block)
      if @backend.respond_to?(meth)
        (class << self; self; end).class_eval do
          define_method(meth) do |*args|
            @backend.send(meth, *args, &block)
          end
        end
        send(meth, *args, &block)
      else
        @backend.method_missing(meth, *args, &block)
      end
    end

    def initialize(archive)
      raise ArgumentError.new unless archive.is_a?(Ar::File)

      @backend = archive

      # read the file header; most of the content is actually in an
      # ASCII-compatible text format, which is very easy to parse
      @name = readexactly(16).rstrip
      @mtime = Time.at(readexactly(12).rstrip.to_i)
      @owner = readexactly(6).rstrip.to_i
      @group = readexactly(6).rstrip.to_i
      @mode = readexactly(8).rstrip.to_i(8)
      @size = readexactly(10).rstrip.to_i
      
      raise File::NotAnAR if readexactly(2) != "\x60\x0a"

      if @name[0..2] == "#1/"
        bsd_name_length = @name[3..-1].to_i

        @name = readexactly(bsd_name_length)
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

      @backend.seek(@size, IO::SEEK_CUR)
    end

    def content
      oldpos = @backend.tell()
      @backend.seek(@offset, IO::SEEK_SET)

      readexactly(@size)
    ensure
      @backend.seek(oldpos, IO::SEEK_SET)
    end
  end
end
