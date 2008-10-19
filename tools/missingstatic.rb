#!/usr/bin/env ruby
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

# check for functions that are not used but in their translation unit

require 'elf'
require 'getoptlong'

opts = GetoptLong.new(
  # Read the files to scan from a file rather than commandline
  ["--filelist", "-f", GetoptLong::REQUIRED_ARGUMENT],
  # Exclude functions with a given prefix (exported functions)
  ["--exclude-regexp", "-x", GetoptLong::REQUIRED_ARGUMENT],
  # Only scan hidden symbols, ignore exported ones
  ["--hidden-only", "-h", GetoptLong::NO_ARGUMENT],
  # Show the type of symbol (function, variable, constant)
  ["--show-type", "-t", GetoptLong::NO_ARGUMENT],
  # Exclude symbols present in a tags file (from exuberant-ctags)
  ["--exclude-tags", "-X", GetoptLong::REQUIRED_ARGUMENT],
  # Show help (man page)
  ["--help", '-?', GetoptLong::NO_ARGUMENT]
)

# The main symbol is used by all the standalone executables,
# reporting it is pointless as it will always be a false
# positive. It cannot be marked static.
#
# The excluded_names variable will contain also all the used symbols
$exclude_names = ["main"]
exclude_regexps = []
files_list = nil
$hidden_only = false
show_type = false

def load_tags_file(filename)
  File.readlines(filename).delete_if do |line|
    line[0..0] == '!' # Internal exuberant-ctags symbol
  end.collect do |line|
    line.split[0]
  end
end

opts.each do |opt, arg|
  case opt
  when '--filelist'
    if arg == '-'
      files_list = $stdin
    else
      files_list = File.new(arg)
    end
  when '--exclude-regexp'
    exclude_regexps << Regexp.new(arg)
  when '--exclude-tags'
    $exclude_names += load_tags_file(arg)
  when '--hidden-only'
    $hidden_only = true
  when '--show-type'
    show_type = true
  when '--help' # Open the man page and go bye...
    # check if we're executing from a tarball or the git repository,
    # if so we can't use the system man page.
    require 'pathname'
    filepath = Pathname.new(__FILE__)
    localman = filepath.dirname + "../manpages" + filepath.basename.sub(".rb", ".1")
    if localman.exist?
      exec("man #{localman.to_s}")
    else
      exec("man missingstatic")
    end
  end
end

$all_defined = []

def scanfile(filename)
  begin
    Elf::File.open(filename) do |elf|
      if elf.type != Elf::File::Type::Rel
        $stderr.puts "missingstatic.rb: #{file}: not an object file"
        next
      end
      unless elf.has_section?('.symtab')
        $stderr.puts "missingstatic.rb: #{file}: no .symtab section found"
        next
      end

      # Gather all the symbols, defined and missing in the translation unit
      elf['.symtab'].symbols.each do |sym|
        if sym.section == Elf::Section::Undef
          $exclude_names << sym.name
        elsif sym.bind == Elf::Symbol::Binding::Local
          next
        elsif (sym.section.is_a? Elf::Section) or
            (sym.section == Elf::Section::Common)
          next if $hidden_only and
            sym.visibility != Elf::Symbol::Visibility::Hidden

          $all_defined << sym
        end
      end
    end
  rescue Errno::ENOENT
    $stderr.puts "missingstatic.rb: #{file}: no such file"
  rescue Elf::File::NotAnELF
    $stderr.puts "missingstatic.rb: #{file}: not a valid ELF file."
  rescue Interrupt
    $stderr.puts "missingstatic.rb: Interrupted"
    exit 1
  rescue Exception => e
    $stderr.puts "missingstatic.rb: Processing #{filename}: #{e.message}"
    $stderr.puts "\t#{e.backtrace.join("\n\t")}"
  end
end

# If there are no arguments passed through the command line
# consider it like we're going to act on stdin.
if not files_list and ARGV.size == 0
  files_list = $stdin
end

if files_list
  files_list.each_line do |file|
    scanfile(file.chomp)
  end
else
  ARGV.each do |file|
    scanfile(file)
  end
end

$exclude_names.uniq!

$all_defined.each do |symbol|
  next if $exclude_names.include? symbol.name

  exclude_regexps.each do |exclude_sym|
    next symbol if exclude_sym.match(symbol.name)
  end

  if show_type
    begin
      prefix = "#{symbol.nm_code} "
    rescue Elf::Symbol::UnknownNMCode => e
      $stderr.puts e.message
      prefix = "? "
    end
  end
  puts "#{prefix}#{symbol.name} (#{symbol.file.path})"
end
