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
require 'set'

opts = GetoptLong.new(
  # Read the files to scan from a file rather than commandline
  ["--filelist", "-f", GetoptLong::REQUIRED_ARGUMENT],
  # Exclude functions with a given prefix (exported functions)
  ["--exclude-regexp", "-x", GetoptLong::REQUIRED_ARGUMENT],
  # Only scan hidden symbols, ignore exported ones
  ["--hidden-only", "-h", GetoptLong::NO_ARGUMENT],
  # Show the type of symbol (function, variable, constant)
  ["--show-type", "-t", GetoptLong::NO_ARGUMENT]
)

exclude_regexps = []
files_list = nil
$hidden_only = false
show_type = false

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
  when '--hidden-only'
    $hidden_only = true
  when '--show-type'
    show_type = true
  end
end

$all_defined = Set.new
$all_using = Set.new
$symbol_objects = {}

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
      this_defined = Set.new
      this_using = Set.new

      elf['.symtab'].symbols.each do |sym|
        if sym.section == Elf::Section::Undef
          this_using << sym.name
        elsif sym.bind == Elf::Symbol::Binding::Local
          next
        elsif (sym.section.is_a? Elf::Section) or
            (sym.section == Elf::Section::Common)
          next if $hidden_only and
            sym.visibility != Elf::Symbol::Visibility::Hidden

          this_defined << sym
          $symbol_objects[sym.name] = filename
        end
      end

      $all_using.merge this_using
      $all_defined.merge this_defined
    end
  rescue Errno::ENOENT
    $stderr.puts "missingstatic.rb: #{file}: no such file"
  rescue Elf::File::NotAnELF
    $stderr.puts "missingstatic.rb: #{file}: not a valid ELF file."
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

$all_defined.subtract $all_using

# The main symbol is used by all the standalone executables, reporting
# it is pointless as it will always be a false positive. It cannot be
# marked static.
$all_defined.delete "main"

$all_defined.delete_if do |symbol|
  excluded = false

  exclude_regexps.each do |re|
    excluded = true if symbol.name =~ re
    break if excluded
  end

  excluded
end

$all_defined.each do |sym|
  if show_type
    begin
      prefix = "#{sym.nm_code} "
    rescue Elf::Symbol::UnknownNMCode => e
      $stderr.puts e.message
      prefix = "? "
    end
  end
  puts "#{prefix} #{sym.name} (#{$symbol_objects[sym.to_s]})"
end
