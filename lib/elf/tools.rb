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

# This file allows to wrap aroudn the most common features of
# Ruby-Elf based tools, that follow a series of common traits.
#
# The tools using this file are tools that inspect a series of ELF
# files, passed through command line, stdin, or through a file
# parameter; they accept a series of arguments that may or might not
# require arguments (in that latter case they are considered on/off
# switches), and so on.

# Gets the name of the tool
def self.to_s
  File.basename($0)
end

# Output an error message, prefixed with the tool name.
def self.puterror(string)
  $stderr.puts "#{to_s}: #{string}"
end

# Parse the arguments for the tool; it does not parse the @file
# options, since they are only expected to contain file names,
# rather than options.
def self.parse_arguments
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
        exec("man #{to_s}")
      end
    end

    attrname = opt.gsub(/^--/, "").gsub("-", "_")
    attrval = arg.size == 0 ? true : arg

    # If there is a function with the same name of the parameter
    # defined (with a _cb suffix), call that, otherwise set the
    # attribute with the same name to the given value.
    if respond_to?(attrname + "_cb")
      method(attrname + "_cb").call(attrval)
    else
      instance_variable_set("@#{attrname}", attrval)
    end
  end
end

# Execute the analysis function, handling the common exception cases
def self.execute(filename)
  begin
    analysis(filename)
  rescue Errno::ENOENT
    puterror "#{filename}: no such file"
  rescue Elf::File::NotAnELF
    puterror "#{filename}: not a valid ELF file."
  rescue Exception => e
    e.message = "#{file}: #{e.message}"
    raise e
  end
end

# Try to execute the analysis function on a given filename; before
# doing that, check if the first character is a @ character, in which
# case load the rest of the parameter as filename and check that.
def self.try_execute(filename)
  if filename[0..1] == "@"
    execute_on_file(filename[1..-1])
  else
    execute(filename)
  end
end

# Execute the analysis function on all the elements of an array.
def self.execute_on_array(array)
  array.each do |filename|
    try_execute(filename)
  end
end

# Execute the analysis function on all the lines of a file
def self.execute_on_file(file)
  file = $stdin if file == "-"
  file = File.new(file) if file.class == String

  file.each_line do |line|
    try_execute(line.chomp("\n"))
  end
end

def self.main
  begin
    before_options
    parse_arguments
    after_options
    
    if ARGV.size == 0
      execute_on_file($stdin)
    else
      execute_on_array(ARGV)
    end
    
    results
  rescue Interrupt
    puterror "Interrupted"
    exit 1
  end
end

at_exit do
  unless $!
    main
  end
end
