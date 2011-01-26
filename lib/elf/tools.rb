# -*- coding: utf-8 -*-
# Copyright © 2008-2010 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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
require 'thread'
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
  return if @quiet

  @output_mutex.synchronize {
    $stderr.puts "#{to_s}: #{string}"
  }
end

# Output a notice about a file, do not prefix with the tool name, do
# not print if doing recursive analysis
def self.putnotice(message)
  return if @quiet or @recursive

  @output_mutex.synchronize {
    $stderr.puts message
  }
end

# Parse the arguments for the tool; it does not parse the @file
# options, since they are only expected to contain file names,
# rather than options.
def self.parse_arguments
  opts = Options + [
                    ["--help", "-?", GetoptLong::NO_ARGUMENT],
                    ["--quiet", "-q", GetoptLong::NO_ARGUMENT],
                    ["--recursive", "-R", GetoptLong::NO_ARGUMENT],
                   ]

  opts = GetoptLong.new(*opts)
  opts.each do |opt, arg|
    if opt == "--help"
      # check if we're executing from a tarball or the git repository,
      # if so we can't use the system man page.
      manpage = File.expand_path("../../../manpages/#{to_s}.1", __FILE__)
      manpage = to_s unless File.exist?(manpage)
      exec("man #{manpage}")
    end

    attrname = opt.gsub(/^--/, "").gsub("-", "_")
    attrval = arg.size == 0 ? true : arg

    # If there is a function with the same name of the parameter
    # defined (with a _cb suffix), call that, otherwise set the
    # attribute with the same name to the given value.
    cb = method("#{attrname}_cb") rescue nil
    case
    when cb.nil?
      instance_variable_set("@#{attrname}", attrval)
    when cb.arity == 0
      raise ArgumentError("wrong number of arguments in callback (0 for 1)") unless
        arg.size == 0
      cb.call
    when cb.arity == 1
      # fallback to provide a single "true" parameter if there was no
      # required argument
      cb.call(attrval)
    else
      raise ArgumentError("wrong number of arguments in callback (#{cb.arity} for #{arg.size})")
    end
  end
end

def execute(filename)
  begin
    analysis(filename)
  rescue Errno::ENOENT, Errno::EACCES, Errno::EISDIR, Elf::File::NotAnELF,
    Elf::File::InvalidElfClass, Elf::File::InvalidDataEncoding,
    Elf::File::UnsupportedElfVersion, Elf::File::InvalidOsAbi, Elf::File::InvalidElfType,
    Elf::File::InvalidMachine => e
    # The Errno exceptions have their message ending in " - FILENAME",
    # so we take the FILENAME out and just use the one we know
    # already.  We also take out the final dot on the phrase so that
    # we follow the output messages from other tools, like cat.
    putnotice "#{filename}: #{e.message.gsub(/\.? - .*/, '')}"
  rescue Exception => e
    puterror "#{filename}: #{e.message} (#{e.class})\n\t#{e.backtrace.join("\n\t")}"
    exit -1
  end
end

# Try to execute the analysis function on a given filename argument.
def self.try_execute(filename)
  begin
    # if the file name starts with '@', it is not a target, but a file
    # with a list of targets, so load it with execute_on_file.
    if filename[0..0] == "@"
      execute_on_file(filename[1..-1])
      return
    end

    # find the file type so we don't have to look it up many times; if
    # we're running a recursive scan, we don't want to look into
    # symlinks as they might create loops or duplicate content, while
    # we usually want to check them out if they are given directly in
    # the list of files to analyse
    file_stat = if @recursive
                  File.lstat(filename)
                else
                  File.stat(filename)
                end

    # if the path references a directory, and we're going to run
    # recursively, descend into that.
    if @recursive and file_stat.directory?
      Dir.foreach(filename) do |children|
        next if children == "." or children == ".."
        try_execute(File.join(filename, children))
      end
    # if the path does not point to a regular file, ignore it
    elsif not file_stat.file?
      putnotice "#{filename}: not a regular file"
    else
      @execution_threads.add(Thread.new {
                               execute(filename)
                             })
    end
  rescue Errno::ENOENT, Errno::EACCES, Errno::EISDIR, Elf::File::NotAnELF => e
    # The Errno exceptions have their message ending in " - FILENAME",
    # so we take the FILENAME out and just use the one we know
    # already.  We also take out the final dot on the phrase so that
    # we follow the output messages from other tools, like cat.
    putnotice "#{filename}: #{e.message.gsub(/\.? - .*/, '')}"
  rescue SystemExit => e
    exit e.status
  rescue Exception => e
    puterror "#{filename}: #{e.message} (#{e.class})\n\t#{e.backtrace.join("\n\t")}"
    exit -1
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
  @single_target = false

  file = $stdin if file == "-"
  file = File.new(file) if file.class == String

  file.each_line do |line|
    try_execute(line.chomp("\n"))
  end
end

def self.main
  begin
    @output_mutex = Mutex.new
    @execution_threads = ThreadGroup.new

    before_options if respond_to? :before_options
    parse_arguments
    after_options if respond_to? :after_options

    # We set the @single_target attribute to true if we're given a
    # single filename as a target, so that tools like elfgrep can
    # avoid printing again the filename on the output. Since we could
    # be given a single @-prefixed file to use as a list, we'll reset
    # @single_target in self.execute_on_file
    @single_target = (ARGV.size == 1)

    if ARGV.size == 0
      execute_on_file($stdin)
    else
      execute_on_array(ARGV)
    end

    @execution_threads.list.each do |thread|
      thread.join
    end

    results if respond_to? :results
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
