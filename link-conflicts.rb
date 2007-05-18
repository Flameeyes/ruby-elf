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

require 'getopt/long'
require 'sqlite3'

opt = Getopt::Long.getopts(
                           ["--input", "-i", Getopt::REQUIRED],
                           ["--output", "-o", Getopt::REQUIRED]
                           )

outfile = opt['output'] ? File.new(opt['output'], "w") : $stdout

db = SQLite3::Database.new( opt['input'] ? opt['input'] : 'symbols-datatabase.sqlite' )

db.execute "SELECT * FROM ( SELECT symbol, abi, COUNT(*) AS occurrences FROM symbols GROUP BY symbol, abi ) WHERE occurrences > 1 ORDER BY occurrences DESC;" do |row|
  outfile.puts "Symbol #{row[0]} (#{row[1]}) present #{row[2]} times"
  db.execute( "SELECT path FROM symbols WHERE symbol='#{row[0]}' AND abi = '#{row[1]}'" ) do |path|
    outfile.puts "  #{path[0]}"
  end
end
