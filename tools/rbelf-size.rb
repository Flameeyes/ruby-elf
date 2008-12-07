#!/usr/bin/env ruby
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

# replacement for size(1) utility that takes into consideration .rodata sections

require 'elf/tools'

Options = []

def self.after_options
  @header = true
end

def self.analysis(file)
  Elf::File.open(file) do |elf|
    results = {
      :exec => 0,
      :data => 0,
      :relro => 0,
      :bss => 0
    }

    elf.each_section do |section|
      case
      when section.type == Elf::Section::Type::NoBits
        results[:bss] += section.size
      when section.flags.include?(Elf::Section::Flags::ExecInstr)
        results[:exec] += section.size
      when (section.flags.include?(Elf::Section::Flags::Write) and
            section.flags.include?(Elf::Section::Flags::Alloc))
        
        # This makes it GCC-specific but that's just because I
        # cannot find anything in ELF specs that gives an easy way
        # to deal with this.
        #
        # By all means, .data.rel.ro is just the same as .data, with
        # the exception of prelinking, where this area can then
        # become mostly read-only and thus not creating dirty pages.
        if section.name == ".data.rel.ro"
          results[:relro] += section.size
        else
          results[:data] += section.size
        end
      end
    end

    results[:dec] = results.values.inject { |sum, val| sum += val }
    results[:hex] = sprintf '%x', results[:dec]

    output_header
    puts "#{results[:exec].to_s.rjust(9)} #{results[:data].to_s.rjust(9)} #{results[:relro].to_s.rjust(9)} #{results[:bss].to_s.rjust(9)} #{results[:dec].to_s.rjust(9)} #{results[:hex].rjust(9)} #{file}"
  end
end

def self.output_header
  if @header
    puts "     exec      data     relro       bss       dec       hex filename"
    @header = false
  end
end
