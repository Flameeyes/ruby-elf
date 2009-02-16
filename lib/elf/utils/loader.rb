# -*- coding: utf-8 -*-
# Copyright © 2009 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

require 'elf'
require 'elf/utils/pool'

# This file provides some utilities to deal with the runtime lodader
# functions. In particular it provides access to the same kind of
# library search as the loader provides.

module Elf
  module Utilities
    @@library_path = nil

    # Return the system library path to look for libraries, just like
    # the loader would.
    def self.system_library_path

      # Try to cache the request since we most likely have multiple
      # request per process and we don't care if the settings change
      # between them.
      if @@library_path.nil?
        @@library_path = []
        # This implements for now the glibc-style loader
        # configuration; in the future it might be reimplemented to
        # take into consideration different operating systems.
        ::File.open("/etc/ld.so.conf") do |ld_so_conf|
          ld_so_conf.each_line do |line|
            # Comment lines in the configuration file are prefixed
            # with the hash character, and the remaining content is
            # just a single huge list of paths, separated by colon,
            # comma, space, tabs or newlines.
            @@library_path.concat line.gsub(/#.*/, '').split(/[:, \t\n]/)
          end
        end
      end
      
      return @@library_path
    end
  end
end
