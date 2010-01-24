# -*- coding: utf-8 -*-
# Copyright © 2009-2010 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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
    @@system_library_path = nil

    # Convenience function to append an array to the list of system
    # library paths.
    #
    # This is just used to avoid repeating the same block of code for
    # both the data read from /etc/ld.so.conf and from LD_LIBRARY_PATH
    # environment variable if requested.
    def self.append_to_library_path(morepaths)
      morepaths.each do |path|
        begin
          # Since we can have symlinks and similar issues, try to
          # canonicalise the paths so that we can expect them to be
          # truly unique (and thus never pass through the same directory
          # twice).
          @@system_library_path << Pathname.new(path).realpath.to_s
        rescue Errno::ENOENT, Errno::EACCES
        end
      end
    end

    # Return the system library path to look for libraries, just like
    # the loader would.
    def self.system_library_path

      # Try to cache the request since we most likely have multiple
      # request per process and we don't care if the settings change
      # between them.
      if @@system_library_path.nil?
        @@system_library_path = Array.new

        # We have to put by default /lib and /usr/lib since they are
        # implicit in all systems. In particular for Gentoo/Linux
        # these two are not in the list on x86 systems (but are on
        # amd64).
        #
        # Since LD_LIBRARY_PATH would win over this, but we expect
        # /etc/ld.so.conf not to, add them here.
        append_to_library_path(["/lib", "/usr/lib"])

        # We might not have the ld.so.conf file, if that's the case
        # just ignore it.
        begin
          # This implements for now the glibc-style loader
          # configuration; in the future it might be reimplemented to
          # take into consideration different operating systems.
          ::File.open("/etc/ld.so.conf") do |ld_so_conf|
            ld_so_conf.each_line do |line|
              # Comment lines in the configuration file are prefixed
              # with the hash character, and the remaining content is
              # just a single huge list of paths, separated by colon,
              # comma, space, tabs or newlines.
              append_to_library_path(line.gsub(/#.*/, '').split(/[:, \t\n]/))
            end
          end
        rescue Errno::ENOENT
        end

        # Make sure the resulting list is uniq to avoid scanning the
        # same directory multiple times.
        @@system_library_path.uniq!
      end
      
      return @@system_library_path
    end

    # Return the environment library path
    #
    # We assume the LD_LIBRARY_PATH variable is not going to change
    # between calls.
    #
    # TODO: systems like Solaris implement further variables like
    # LD_LIBRARY_PATH_32 and LD_LIBRARY_PATH_64, we should pay
    # attention to those too.
    def self.environment_library_path
      return [] if ENV['LD_LIBRARY_PATH'].nil?

      ENV['LD_LIBRARY_PATH'].split(":").collect do |path|
        begin
          Pathname.new(path).realpath.to_s
        rescue Errno::ENOENT, Errno::EACCES
        end
      end.uniq
    end
  end
end
