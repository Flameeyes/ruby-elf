#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Copyright © 2011 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

require 'elf/tools'

Options = [
           # Expression to match on the symbol name
           ["--regexp", "-e", GetoptLong::REQUIRED_ARGUMENT],
           # Append the version information when matching the symbol
           # name
           ["--match-version", "-V", GetoptLong::NO_ARGUMENT],
           # Don't match undefined symbols
           ["--no-match-undefined", "-U", GetoptLong::NO_ARGUMENT],
           # Don't match defined symbols
           ["--no-match-defined", "-D", GetoptLong::NO_ARGUMENT],
           # Invert selection, show symbols not matching the
           # expression
           ["--invert-match", "-v", GetoptLong::NO_ARGUMENT],
           # List only files with matches
           ["--files-with-matches", "-l", GetoptLong::NO_ARGUMENT],
           # List only files without match
           ["--files-without-match", "-L", GetoptLong::NO_ARGUMENT],
           # Print the name of the file for each match
           ["--with-filename", "-H", GetoptLong::NO_ARGUMENT],
           # Don't print the name of the file for each match
           ["--no-filename", "-h", GetoptLong::NO_ARGUMENT]
          ]

# We define callbacks for some behaviour-changing options as those
# will let us consider them positionally, similar to what grep(1)
# does. If you try -lLl and similar combinations on grep(1), the last
# one passed is the one to be considered.

def self.files_with_matches_cb
  @show = :files_with_matches
end

def self.files_without_match_cb
  @show = :files_without_match
end

def self.with_filename_cb
  @print_filename = true
end

def self.no_filename_cb
  @print_filename = false
end

# we make this a method so that we don't have to worry about deciding
# on the base of how many targets we have; we have to do this
# because we cannot know, in after_options, whether the user passed
# @-file lists.
def self.print_filename
  @print_filename = !@single_target if @print_filename.nil?

  @print_filename
end

def self.before_options
  @invert_match = false
  @match_undefined = true
  @match_defined = true
  @show = :full_match
end

def self.after_options
  if @regexp.nil?
    puterror "you need to provide an expression"
    exit -1
  end

  if @no_match_undefined and @no_match_defined
    puterror "you need to match at least defined or undefined symbols"
    exit -1
  end

  @match_undefined = !@no_match_undefined
  @match_defined = !@no_match_defined
  @regexp = Regexp.new(@regexp)
end

def self.analysis(file)
  Elf::File.open(file) do |elf|
    if not elf.has_section?(".dynsym") or
        elf[".dynsym"].class != Elf::SymbolTable
      putnotice "#{file}: not a dynamically linked file"
      return
    end

    gotmatch = false
    elf[".dynsym"].each do |symbol|
      next if
        (symbol.section == Elf::Section::Abs) or
        (symbol.name == '') or
        (symbol.section == Elf::Section::Undef and
         not @match_undefined) or
        (symbol.section != Elf::Section::Undef and
         not @match_defined)

      symname = symbol.name
      symname += "@#{symbol.version}" if @match_version

      # We don't care where it matches, but we do care that it matches
      # or not; we use an invert match since we have to further compare
      # that to @invert_match
      matched = (@invert_match == (@regexp =~ symname).nil?)
      gotmatch ||= matched

      if matched
        break unless @show == :full_match

        puts "#{"#{file} " if print_filename}#{symbol.nm_code rescue '?'} #{symname}"
      end
    end

    case @show
    when :files_with_matches
      puts file if gotmatch
    when :files_without_match
      puts file if not gotmatch
    end
  end
end
