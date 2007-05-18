#!/usr/bin/env ruby
# Copyright © 2007, Diego "Flameeyes" Pettenò <flameeyes@gmail.com>
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
require 'sqlite3'

opts = GetoptLong.new(
  ["--input", "-i", GetoptLong::REQUIRED_ARGUMENT],
  ["--output", "-o", GetoptLong::REQUIRED_ARGUMENT]
)

outfile = $stdout
input_database = 'symbols-database.sqlite'

opts.each do |opt, arg|
  case opt
  when '--output'
    outfile = File.new(arg, "w")
  when '--input'
    input_database = arg
  end
end

db = SQLite3::Database.new input_database

db.execute "SELECT * FROM ( SELECT symbol, abi, COUNT(*) AS occurrences FROM symbols GROUP BY symbol, abi ) WHERE occurrences > 1 ORDER BY occurrences DESC;" do |row|
  outfile.puts "Symbol #{row[0]} (#{row[1]}) present #{row[2]} times"
  db.execute( "SELECT path FROM symbols WHERE symbol='#{row[0]}' AND abi = '#{row[1]}'" ) do |path|
    outfile.puts "  #{path[0]}"
  end
end
