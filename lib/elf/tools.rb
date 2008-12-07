# -*- coding: utf-8 -*-
# Copyright © 2008, Diego "Flameeyes" Pettenò <flameeyes@gmail.com>
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
require 'elf'

# Base class used for Ruby-Elf based tools
#
# This class allows to wrap aroudn the most common features of
# Ruby-Elf based tools, that follow a series of common traits.
#
# The tools using this class are tools that inspect a series of ELF
# files, passed through command line, stdin, or through a file
# parameter; they accept a series of arguments that may or might not
# require arguments (in that latter case they are considered on/off
# switches), and so on.
module Elf::Tool
  # Parse the arguments for the tool; it does not parse the @file
  # options, since they are only expected to contain file names,
  # rather than options.
  def parse_arguments
    opts = Options + [["--help", "-?", GetoptLong::NO_ARGUMENT]]

    opts = GetoptLong.new(*opts)
    opts.each do |opt, arg|
      if opt == "--help"
        # check if we're executing from a tarball or the git repository,
        # if so we can't use the system man page.
        require 'pathname'
        filepath = Pathname.new($0)
        localman = filepath.dirname + "../manpages" + filepath.basename.sub(".rb", ".1")
        if localman.exist?
          exec("man #{localman.to_s}")
        else
          exec("man missingstatic")
        end
      end

      attrname = "@" + opt.gsub(/^--/, "").gsub("-", "_")
      attrval = arg.size == 0 ? true : arg
      
      instance_variable_set(attrname, attrval)
    end
  end

  # Execute the analysis function on a given filename; but before
  # doing that, check if the first character is a @ character, in
  # which case load the rest of the parameter as filename and check
  # that.
  def execute(filename)
    if filename[0..1] == "@"
      execute_on_file(filename[1..-1])
    else
      analysis(filename)
    end
  end

  # Execute the analysis function on all the elements of an array.
  def execute_on_array(array)
    array.each do |filename|
      execute(filename)
    end
  end

  # Execute the analysis function on all the lines of a file
  def execute_on_file(file)
    file = $stdin if file == "-"
    file = File.new(file) if file.class == String

    file.each_line do |line|
      execute(line.chomp("\n"))
    end
  end

  def main
    before_options
    parse_arguments
    after_options

    if ARGV.size == 0
      execute_on_file($stdin)
    else
      execute_on_array(ARGV)
    end

    results
  end
end

at_exit do
  unless $!
    main
  end
end
