#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Copyright © 2007-2008, Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

# This script is used to harvest the symbols defined in the shared
# objects of the whole system.

require 'getoptlong'
require 'postgres'

opts = GetoptLong.new(
  ["--suppressions",       "-s", GetoptLong::REQUIRED_ARGUMENT ],
  ["--postgres-username",  "-U", GetoptLong::REQUIRED_ARGUMENT ],
  ["--postgres-password",  "-P", GetoptLong::REQUIRED_ARGUMENT ],
  ["--postgres-hostname",  "-H", GetoptLong::REQUIRED_ARGUMENT ],
  ["--postgres-port",      "-T",  GetoptLong::REQUIRED_ARGUMENT ],
  ["--postgres-database",  "-D", GetoptLong::REQUIRED_ARGUMENT ]
)

suppression_files = File.exist?('suppressions') ? [ 'suppressions' ] : []

pg_params = {}

opts.each do |opt, arg|
  case opt
  when '--suppressions'
    unless File.exist? arg
      $stderr.puts "harvest.rb: no such file or directory - #{arg}"
      exit -1
    end
    suppression_files << arg
  when '--postgres-username' then pg_params['user'] = arg
  when '--postgres-password' then pg_params['password'] = arg
  when '--postgres-hostname' then pg_params['host'] = arg
  when '--postgres-port'     then pg_params['port'] = arg
  when '--postgres-database' then pg_params['dbname'] = arg
  end
end

db = PGconn.open(pg_params)

db.exec("BEGIN TRANSACTION")

# Total suppressions are for directories to skip entirely
# Partial suppressions are the ones that apply only to a subset
# of symbols.
suppression_files.each do |suppression|
  File.open(suppression) do |file|
    file.each_line do |line|
      path, symbols = line.
        gsub(/#\s.*/, '').
        strip!.
        split(/\s+/, 2)
      
      next unless path
      
      if not symbols or symbols == ""
        # the POSIX regular expressions and the Ruby ones differ from
        # how + and \+ are used. PgSQL uses POSIX.
        path = path.gsub('+', '\+').gsub('\\+', '+')
        db.exec("DELETE FROM objects WHERE name ~ '#{path}'")
      else
        symbols.sub!(/(\$)?$/, '@@\1')
        db.exec("DELETE FROM symbols WHERE symbol ~ '#{symbols}' AND object IN (SELECT id FROM objects WHERE name ~ '#{path}')")
      end
    end
  end
end

db.exec("COMMIT")
