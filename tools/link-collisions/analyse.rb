#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Copyright © 2007-2008, Diego "Flameeyes" Pettenò <flameeyes@gmail.com>
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

require 'getoptlong'
require 'rubygems'
require 'postgres'

opts = GetoptLong.new(
  ["--input", "-i", GetoptLong::REQUIRED_ARGUMENT],
  ["--output", "-o", GetoptLong::REQUIRED_ARGUMENT],
  ["--postgres-username",  "-U", GetoptLong::REQUIRED_ARGUMENT ],
  ["--postgres-password",  "-P", GetoptLong::REQUIRED_ARGUMENT ],
  ["--postgres-hostname",  "-H", GetoptLong::REQUIRED_ARGUMENT ],
  ["--postgres-port",      "-T", GetoptLong::REQUIRED_ARGUMENT ],
  ["--postgres-database",  "-D", GetoptLong::REQUIRED_ARGUMENT ]
)

outfile = $stdout

pg_params = {}

opts.each do |opt, arg|
  case opt
  when '--output'
    outfile = File.new(arg, "w")
  when '--input'
    input_database = arg
  when '--postgres-username' then pg_params['user'] = arg
  when '--postgres-password' then pg_params['password'] = arg
  when '--postgres-hostname' then pg_params['host'] = arg
  when '--postgres-port'     then pg_params['port'] = arg
  when '--postgres-database' then pg_params['dbname'] = arg
  end
end

db = PGconn.open(pg_params)

db.exec("PREPARE getinstances (text, text) AS
         SELECT path FROM symbols INNER JOIN objects ON symbols.object = objects.id WHERE symbol = $1 AND abi = $2")

db.exec("SELECT * FROM duplicate_symbols;").each do |row|
  outfile.puts "Symbol #{row[0]} (#{row[1]}) present #{row[2]} times"
  db.exec( "EXECUTE getinstances ('#{row[0]}', '#{row[1]}')" ).each do |path|
    outfile.puts "  #{path[0]}"
  end
end
