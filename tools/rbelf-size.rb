#!/usr/bin/env ruby
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

# replacement for size(1) utility that takes into consideration .rodata sections

require 'elf/tools'

Options = [
           # Give relocation data for shared object assesment
           ["--relocation-stats", "-r", GetoptLong::NO_ARGUMENT],
           # Use deciBel scale for the shared-to-relocated ratio
           ["--decibel", "-d", GetoptLong::NO_ARGUMENT]
          ]

def self.before_options
  @relocation_stats = false
end

def self.after_options
  @header = true
end

def self.analysis(file)
  Elf::File.open(file) do |elf|
    results = {
      :exec => 0,
      :data => 0,
      :rodata => 0,
      :relro => 0,
      :bss => 0,
      :total => 0
    }

    # Get the size of each section, and then, depending on its type,
    # flags and eventually name, decide what to sum it to.
    elf.each_section do |section|
      case
      # When the section is NoBits, it is not allocated in the file,
      # and is only allocated in ram, this is the case of .bss and
      # .tbss sections.
      when section.type == Elf::Section::Type::NoBits
        sectype = :bss
      # If the section contains executable code, count it separately;
      # size(1) will count it all as text, but we don't need to do
      # that.
      when section.flags.include?(Elf::Section::Flags::ExecInstr)
        sectype = :exec
      # If the section is going to be allocated and writeable at
      # runtime, it is usually a data section, of some kind.
      #
      # We check further though since we might want to count it
      # separately.
      when (section.flags.include?(Elf::Section::Flags::Write) and
            section.flags.include?(Elf::Section::Flags::Alloc))
        
        # This makes it GCC-specific but that's just because I
        # cannot find anything in ELF specs that gives an easy way
        # to deal with this.
        #
        # By all means, .data.rel.ro is just the same as .data, with
        # the exception of prelinking, where this area can then
        # become mostly read-only and thus not creating dirty pages.
        sectype = (section.name =~ /^\.data\.rel\.ro(\..+)?/) ? :relro : :data
      when section.flags.include?(Elf::Section::Flags::Alloc)
        sectype = :rodata
      end

      results[sectype] += section.size unless sectype.nil?
    end

    results[:total] = results.values.inject { |sum, val| sum += val }

    if @relocation_stats
      relocation_stats(results, file)
    else
      standard_size(results, file)
    end
  end
end

def self.relocation_stats(results, file)
  if @header
    puts "      shared      private    relocated        ratio   filename"
    @header = false
  end

  size_shared = results[:exec] + results[:rodata]
  size_private = results[:data] + results[:bss]
  size_relocated = results[:relro]

  ratio = size_shared.to_f/size_relocated
  ratio = 10 * Math::log10(ratio) if @decibel

  printf "% 12s % 12s % 12s % 12.2f   %s\n", size_shared, size_private, size_relocated, ratio, file
end

def self.standard_size(results, file)
  if @header
    puts "     exec      data    rodata     relro       bss     total filename"
    @header = false
  end

  results.each_pair do |key, val|
    results[key] = val.to_s.rjust(9)
  end

  puts "#{results[:exec]} #{results[:data]} #{results[:rodata]} #{results[:relro]} #{results[:bss]} #{results[:total]} #{file}"
end
