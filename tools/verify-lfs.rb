#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Copyright © 2010 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

# This script verifies whether a file or a tree of files is using
# non-LFS interfaces, or mixing non-LFS and LFS interfaces.

require 'elf/tools'

Options = [
           # Scan only object files (rather than non-object files)
           ["--objects", "-o", GetoptLong::NO_ARGUMENT]
          ]

SymbolNamesList = [
                   "__[fl]?xstat",
                   "statv?fs",
                   "(|_IO_)f[gs]etpos",
                   "(read|scan)dir",
                   "getdirentries",
                   "mko?stemp",
                   "(|__)p(read|write)",
                   "p(read|write)v",
                   "(send|tmp)file",
                   "[gs]etrlimit",
                   "versionsort",
                   "f?truncate",
                   "(|f(|re))open",
                   "openat",
                   "fseeko",
                   "ftello",
                   "lseek",
                   "glob(|free)",
                   "ftw",
                   "lockf"
                  ]

SymbolNames = "(#{SymbolNamesList.join("|")})"

def self.before_options
end

def self.after_options
  @files_mixing = []
  @files_nolfs = []

  if @objects
    @elftypes = [ Elf::File::Type::Rel ]
    @elfdescr = "a relocatable object file"
    @elftable = ".symtab"
  else
    @elftypes = [ Elf::File::Type::Exec, Elf::File::Type::Dyn ]
    @elfdescr = "an executable or dynamic file"
    @elftable = ".dynsym"
  end
end

def self.analysis(file)
  Elf::File.open(file) do |elf|
    unless @elftypes.include? elf.type
      puterror "#{file}: not #{@elfdescr}"
      next
    end

    if not elf.has_section?(@elftable) or elf[@elftable].class != Elf::SymbolTable
      puterror "#{file}: not a dynamically linked file"
      next
    end

    if elf.elf_class == Elf::Class::Elf64
      puterror "#{file}: testing 64-bit ELF files is meaningless"
      next
    end

    use_stat32 = false
    use_stat64 = false

    elf[@elftable].each do |symbol|
      next unless symbol.section == Elf::Section::Undef

      use_stat32 ||= (symbol.to_s =~ /^#{SymbolNames}$/)
      use_stat64 ||= (symbol.to_s =~ /^#{SymbolNames}64$/)

      # avoid running the whole list if we hit both as we cannot hit
      # _more_
      break if use_stat32 and use_stat64
    end

    if use_stat32 and use_stat64
      @files_mixing << file
    elsif use_stat32 and not use_stat64
      @files_nolfs << file
    end
  end
end

def self.results
  if @files_mixing.size > 0
    puts "The following files are mixing LFS and non-LFS library calls:"
    puts "  " + @files_mixing.join("\n  ")
  end
  if @files_nolfs.size > 0
    puts "The following files are using non-LFS library calls:"
    puts "  " + @files_nolfs.join("\n  ")
  end
end
