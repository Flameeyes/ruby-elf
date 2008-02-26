#!/usr/bin/env ruby
# Copyright © 2006-2008, Diego "Flameeyes" Pettenò <flameeyes@gmail.com>
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

# == Synopsis
#
# bindings-parser: parses the LD_DEBUG=bindings output
#
# == Usage
# 
# bindings-parser [-S] [-b] [-l library] [-f file]
#
# -h, --help:
#    show help
#
# -S, --sort
#    Sort the statistics by amount of entries.
#
# -b, --basename-only
#    Report only the basename of libraries (shorter).
#
# -l <basename>, --library <basename>
#    Report only the statistics for the given library.
#
# -f <inputfile>, --file <inputfile>
#    Reads the output to parse from file rather than standard input.
#
# Feed the standard input (or the file) with the outptu created by
# LD_DEBUG=bindings somecommand
# You can use LD_DEBUG_OUTPUT to write the output to a file rather than
# stderr.

pid = nil

require 'getoptlong'
require 'rdoc/usage'

opts = GetoptLong.new(
                      ["--help", "-h", GetoptLong::NO_ARGUMENT],
                      ["--sort", "-S", GetoptLong::NO_ARGUMENT],
                      ["--basename-only", "-b", GetoptLong::NO_ARGUMENT],
                      ["--library", "-l", GetoptLong::REQUIRED_ARGUMENT],
                      ["--file", "-f", GetoptLong::REQUIRED_ARGUMENT]
                      )

sort = false
basename = false
library = nil
input = $stdin

opts.each do |opt, arg|
  case opt
  when "--help"
    RDoc::usage
  when "--sort"
    sort = true
  when "--basename-only"
    basename = true
  when "--library"
    library = arg
  when "--file"
    input = File.new(arg, "r")
  end
end

bindings = []

input.each_line { |line|
  if line =~ /\s+(\d+):\s+binding file ([^\s]+) \[0\] to ([^\s]+) \[0\]: (\w+) symbol .*/
    
    pid = $1.to_i unless pid

    if basename or library
      bindings << { :origin => File.basename($2), :destination => File.basename($3), :type => $4 }
    else
      bindings << { :origin => $2, :destination => $3, :type => $4 }
    end

  end
}

maxlen = 0

bindings.each { |b| maxlen = [maxlen, b[:origin].size, b[:destination].size, b[:type].size].max }

maxlen += 4

origins = bindings.collect { |b| b[:origin] }.uniq.sort
destinations = bindings.collect { |b| b[:destination] }.uniq.sort
bindtypes = bindings.collect { |b| b[:type] }.uniq.sort

origcount = origins.collect { |key| [ key, bindings.clone.delete_if { |e| e[:origin] != key }.size ] }
destcount = destinations.collect { |key| [ key, bindings.clone.delete_if { |e| e[:destination] != key }.size ] }
typescount = bindtypes.collect { |key| [ key, bindings.clone.delete_if { |e| e[:type] != key }.size ] }
selfcount = origins.collect { |key| [ key, bindings.clone.delete_if { |e| e[:origin] != key or e[:destination] != key }.size ] }

if sort
  [origcount, destcount, typescount, selfcount].each { |countarray|
    countarray.sort! { |k1, k2| k2[1] <=> k1[1] } # [1] is the count
  }
else
  [origcount, destcount, typescount, selfcount].each { |countarray|
    countarray.sort! { |k1, k2| k2[0] <=> k1[0] } # [0] is the name
  }
end

if not library
  puts "Statistics"
  
  puts "  Origins"
  origcount.each { |key, count|
    print "    #{key}"
    (maxlen-key.size).times { print " " }
    puts "#{count}"
  }
  
  puts "  Destinations"
  destcount.each { |key, count|
    print "    #{key}"
    (maxlen-key.size).times { print " " }
    puts "#{count}"
  }
  
  puts "  Bindtypes"
  typescount.each { |key, count|
    print "    #{key}"
    (maxlen-key.size).times { print " " }
    puts "#{count}"
  }
  
  puts "  Self-loops (candidate for protected visibility)"
  selfcount.each { |key, count|
    next if count == 0
    print "    #{key}"
    (maxlen-key.size).times { print " " }
    puts "#{count}"
  }
else
  puts "Statistics for #{library}"
  puts "  Origin:       #{origcount.assoc(library)[1].to_s.rjust(8)}" if origcount.assoc(library)
  puts "  Destination:  #{destcount.assoc(library)[1].to_s.rjust(8)}" if destcount.assoc(library)
  puts "  Self-loops:   #{selfcount.assoc(library)[1].to_s.rjust(8)}" if selfcount.assoc(library)
end
