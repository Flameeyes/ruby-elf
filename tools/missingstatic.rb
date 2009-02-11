#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Copyright © 2008-2009 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

require 'elf/tools'

Options = [
           # Exclude functions with a given prefix (exported functions)
           ["--exclude-regexp", "-x", GetoptLong::REQUIRED_ARGUMENT],
           # Only scan hidden symbols, ignore exported ones
           ["--hidden-only", "-h", GetoptLong::NO_ARGUMENT],
           # Show the type of symbol (function, variable, constant)
           ["--show-type", "-t", GetoptLong::NO_ARGUMENT],
           # Exclude symbols present in a tags file (from exuberant-ctags)
           ["--exclude-tags", "-X", GetoptLong::REQUIRED_ARGUMENT]
          ]

def self.exclude_tags_cb(arg)
  @exclude_names += File.readlines(arg).delete_if do |line|
    line[0..0] == '!' # Internal exuberant-ctags symbol
  end.collect do |line|
    line.split[0]
  end
end

def self.exclude_regexp_cb(arg)
  @exclude_regexps << Regexp.new(arg)
end

def self.before_options
  # The main symbol is used by all the standalone executables,
  # reporting it is pointless as it will always be a false
  # positive. It cannot be marked static.
  #
  # The excluded_names variable will contain also all the used symbols
  @exclude_names = ["main"]
  @exclude_regexps = []
  @hidden_only = false
  @show_type = false
end

def self.after_options
  @all_defined = []
end

def self.analysis(filename)
  Elf::File.open(filename) do |elf|
    if elf.type != Elf::File::Type::Rel
      puterror "#{file}: not an object file"
      next
    end
    unless elf.has_section?('.symtab')
      puterror "#{file}: no .symtab section found"
      next
    end

    # Gather all the symbols, defined and missing in the translation unit
    elf['.symtab'].each_symbol do |sym|
      if sym.section == Elf::Section::Undef
        @exclude_names << sym.name
      elsif sym.bind == Elf::Symbol::Binding::Local
        next
      elsif (sym.section.is_a? Elf::Section) or
          (sym.section == Elf::Section::Common)
        next if @hidden_only and
          sym.visibility != Elf::Symbol::Visibility::Hidden

        @all_defined << sym
      end
    end
  end
end

def self.results
  @exclude_names.uniq!

  @all_defined.each do |symbol|
    next if @exclude_names.include? symbol.name

    excluded = false
    @exclude_regexps.each do |exclude_sym|
      break if excluded = exclude_sym.match(symbol.name)
    end
    next if excluded

    if @show_type
      begin
        prefix = "#{symbol.nm_code} "
      rescue Elf::Symbol::UnknownNMCode => e
        puterror e.message
        prefix = "? "
      end
    end
    puts "#{prefix}#{symbol.name} (#{symbol.file.path})"
  end
end
