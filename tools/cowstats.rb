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

# simple script to check for variables in copy-on-write sections

require 'elf'
require 'getoptlong'

opts = GetoptLong.new(
  # Only show statistics for the various files
  ["--statistics", "-s", GetoptLong::NO_ARGUMENT],
  # Show the total size of COW pages
  ["--total", "-t", GetoptLong::NO_ARGUMENT],
  # Read the file to check from a file rather than commandline
  ["--filelist", "-f", GetoptLong::REQUIRED_ARGUMENT],
  # Ignore C++ "false positives" (vtables and typeinfo)
  ["--ignore-cxx", "-x", GetoptLong::NO_ARGUMENT ],
  # Ignore Profiling false positives
  ["--ignore-profiling", "-p", GetoptLong::NO_ARGUMENT ]
)

$stats_only = false
$show_total = false
file_list = nil
$ignore_cxx = false
$ignore_profiling = false

opts.each do |opt, arg|
  case opt
  when '--statistics'
    $stats_only = true
  when '--total'
    $show_total = true
  when '--filelist'
    if arg == '-'
      file_list = $stdin
    else
      file_list = File.new(arg)
    end
  when '--ignore-cxx'
    $ignore_cxx = true
  when '--ignore-profiling'
    $ignore_profiling = true
  end
end

$files_info = {}

if $show_total
  $data_total = 0
  $bss_total = 0
  $rel_total = 0
end

def cowstats_scan(file)
  data_vars = []
  data_size = 0
  bss_vars = []
  bss_size = 0
  rel_vars = []
  rel_size = 0
  
  begin
    Elf::File.open(file) do |elf|
      if elf.type != Elf::File::Type::Rel
        $stderr.puts "cowstats.rb: #{file}: not an object file"
        next
      end
      if elf['.symtab'] == nil
        $stderr.puts "cowstats.rb: #{file}: no .symtab section found"
        next
      end

      elf['.symtab'].symbols.each do |symbol|
        # Ignore undefined, absolute and common symbols.
        next unless symbol.section.is_a? Elf::Section
        # When the symbol name is empty, it refers to the
        # section itself.
        next if symbol.name == ""

        # Ignore C++ vtables and other symbols when requested
        next if $ignore_cxx and symbol.name =~ /^_ZT[VI](N[0-9]+[A-Z_].*)*[0-9]+[A-Z_].*/
        # Ignore profiling symbols when requested by user
        next if $ignore_profiling and symbol.name =~ /^__gcov_/
        
        # If the section is NoBits, then it's .bss or equivalent, handle
        # and skip right away.
        if symbol.section.type == Elf::Section::Type::NoBits
          bss_vars << symbol unless $stats_only
          bss_size += symbol.size
          next
        end

        # Ignore executable code (.text, .init, .fini)
        next if symbol.section.flags.include? Elf::Section::Flags::ExecInstr
        # Ignore read-only sections (.rodata)
        next unless symbol.section.flags.include? Elf::Section::Flags::Write
        # Ignore non-allocated sections (all data sections are allocated)
        next unless symbol.section.flags.include? Elf::Section::Flags::Alloc

        # Until I can find a way to distinguish between relocated and
        # non-relocated sections, still use the name to choose between
        # them. If the name is not in this list, at least warn now
        # about it.
        case symbol.section.name
        when /^\.data\.rel(\.ro)?(\.local)?(\..*)?/
          rel_vars << symbol unless $stats_only
          rel_size += symbol.size
        when /^\.t?data(\.local)?(\..*)?/
          data_vars << symbol unless $stats_only
          data_size += symbol.size
        else
          $stderr.puts "symbol #{symbol.name} in unknown section #{symbol.section.name}"
        end
      end
      
    end
  rescue Errno::ENOENT
    $stderr.puts "cowstats.rb: #{file}: no such file"
    return
  rescue Elf::File::NotAnELF
    $stderr.puts "cowstats.rb: #{file}: not a valid ELF file."
    return
  rescue Exception => e
    $stderr.puts "cowstats.rb: #{file}: #{e.message}"
    $stderr.puts "\t" + e.backtrace.join("\n\t")
  end

  return unless (data_size + bss_size + rel_size ) > 0

  if $show_total
    $data_total += data_size
    $bss_total += bss_size
    $rel_total += rel_size
  end
    
  if $stats_only
    $files_info[file] = {
      :data_size => data_size,
      :bss_size => bss_size,
      :rel_size => rel_size
    }
    return
  end

  puts "Processing file #{file}"
    
  if data_vars.length > 0
    puts "  The following variables are writable (Copy-On-Write):"
    data_vars.each do |sym|
      puts "    #{sym} (size: #{sym.size})"
    end
  end
  
  if bss_vars.length > 0
    puts "  The following variables aren't initialised (Copy-On-Write):"
    bss_vars.each do |sym|
      puts "    #{sym} (size: #{sym.size})"
    end
  end
  
  if rel_vars.length > 0
    puts "  The following variables need runtime relocation (Copy-On-Write):"
    rel_vars.each do |sym|
      puts "    #{sym} (size: #{sym.size})"
    end
  end
  
  if $show_total
    puts "  Total writable variables size: #{data_size}" unless data_size == 0
    puts "  Total non-initialised variables size: #{bss_size}" unless bss_size == 0
    puts "  Total variables needing runtime relocation size: #{rel_size}" unless rel_size == 0
  end
end

# If there are no arguments passed through the command line
# consider it like we're going to act on stdin.
if not file_list and ARGV.size == 0
  file_list = $stdin
end

if file_list
  file_list.each_line do |file|
    cowstats_scan(file.chomp)
  end
else
  ARGV.each do |file|
    cowstats_scan(file)
  end
end

if $stats_only
  file_lengths = ["File name".length]
  data_lengths = [".data size".length]
  bss_lengths  = [".bss size".length]
  rel_lengths  = [".data.rel.* size".length]
  $files_info.each_pair do |file, info|
    file_lengths << file.length
    data_lengths << info[:data_size].to_s.length
    bss_lengths  << info[:bss_size] .to_s.length
    rel_lengths  << info[:rel_size] .to_s.length
  end

  maxlen       = file_lengths.max
  max_data_len = data_lengths.max
  max_bss_len  = bss_lengths .max
  max_rel_len  = rel_lengths .max

  puts "#{'File name'.ljust maxlen} | #{'.data size'.ljust max_data_len} | #{'.bss size'.ljust max_data_len} | #{'.data.rel.* size'.ljust max_data_len}"
  $files_info.each do |file, info|
    puts "#{file.ljust maxlen}   #{info[:data_size].to_s.rjust max_data_len}   #{info[:bss_size].to_s.rjust max_bss_len}   #{info[:rel_size].to_s.rjust max_rel_len}"
  end
end

if $show_total
  data_total_real = $data_total > 0 ? (($data_total/4096) + ($data_total % 4096 ? 1 : 0)) * 4096 : 0
  bss_total_real = $bss_total > 0 ? (($bss_total/4096) + ($bss_total % 4096 ? 1 : 0)) * 4096 : 0 
  rel_total_real = $rel_total > 0 ? (($rel_total/4096) + ($rel_total % 4096 ? 1 : 0)) * 4096 : 0

  puts "Totals:"
  puts "    #{$data_total} (#{data_total_real} \"real\") bytes of writable variables."
  puts "    #{$bss_total} (#{bss_total_real} \"real\") bytes of non-initialised variables."
  puts "    #{$rel_total} (#{rel_total_real} \"real\") bytes of variables needing runtime relocation."
  puts "  Total #{$data_total+$bss_total+$rel_total} (#{data_total_real+bss_total_real+rel_total_real} \"real\") bytes of variables in copy-on-write sections"
end
