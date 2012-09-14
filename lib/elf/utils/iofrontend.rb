# -*- coding: utf-8 -*-
# Copyright © 2009 Alex Legler <a3li@gentoo.org>
# Copyright © 2009-2010 Diego Elio Pettenò <flameeyes@flameeyes.eu>
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

module Elf::Utilities
  # This class is useful to allow access of something that acts like
  # an IO and simulate its own behaviour in front of it.
  class IOFrontend
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

    def method_missing(meth, *args, &block)
      if @backend.respond_to?(meth)
        (class << self; self; end).class_eval do
          define_method(meth) do |*args|
            @backend.send(meth, *args, &block)
          end
        end
        send(meth, *args, &block)
      else
        super
      end
    end

    def initialize(param)
      if param.is_a?(IO) or param.is_a?(StringIO) or param.is_a?(Ar::Entry)
        @backend = param
      elsif param.respond_to?(:to_s)
        param = param.to_s

        _checkvalidpath(param)

        @backend = ::File.new(param, "rb")
      else
        raise ArgumentError.new
      end
    end
  end
end
