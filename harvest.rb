#!/usr/bin/env ruby
# Copyright © 2007, Diego "Flameeyes" Pettenò <flameeyes@gmail.com>
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

# This script is used to harvest the symbols defined in the shared
# objects of the whole system.

require 'getopt/long'
require 'set'
require 'pathname'
require 'sqlite3'
require 'elf'

opt = Getopt::Long.getopts(
                           ["--output", "-o", Getopt::REQUIRED],
                           ["--pathscan", "-p", Getopt::BOOLEAN]
                           )

# First of all, load the suppression files.
# These are needed to skip paths like /lib/modules
xdg_config_paths = ["."]
xdg_config_paths << (ENV['XDG_CONFIG_HOME'] ? ENV['XDG_CONFIG_HOME'] : "#{ENV['HOME']}/.config")
xdg_config_paths += ENV['XDG_CONFIG_DIRS'].split(":") if ENV['XDG_CONFIG_DIRS']
xdg_config_paths << "/etc/xdg"

# Total suppressions are for directories to skip entirely
# Partial suppressions are the ones that apply only to a subset
# of symbols.
$total_suppressions = []
$partial_suppressions = []

xdg_config_paths.each do |dir|
  path = Pathname.new(dir) + "link-conflicts.suppressions"

  next unless path.exist?

  path.each_line do |line|
    path, symbols = line.strip!.split(/\s+/, 2)

    if not symbols or symbols == ""
      $total_suppressions << Regexp.new(path)
    else
      $partial_suppressions << [Regexp.new(path), Regexp.new(symbols)]
    end
  end
end

ldso_paths = Set.new
ldso_paths.merge ENV['LD_LIBRARY_PATH'].split(":").set if ENV['LD_LIBRARY_PATH']

File.open("/etc/ld.so.conf") do |ldsoconf|
  ldso_paths.merge ldsoconf.readlines.
    delete_if { |l| l =~ /\s*#.*/ }.
    collect { |l| l.strip }.
    uniq
end

so_files = Set.new

# Extend Pathname with a so_files method
class Pathname
  def so_files(recursive = true)
    res = Set.new
    each_entry do |entry|
      begin
        next if entry.to_s =~ /\.\.?$/
        entry = (self + entry).realpath

        skip = false

        $total_suppressions.each do |supp|
          if entry.to_s =~ supp
            skip = true
            break
          end
        end

        next if skip

        if entry.directory?
          res.merge entry.so_files if recursive
          next
        elsif entry.to_s =~ /\.so[\.0-9]*$/
          res.add entry.to_s
        end
      rescue Errno::EACCES, Errno::ENOENT
        next
      end
    end

    return res
  end
end

ldso_paths.each do |path|
  begin
    so_files.merge Pathname.new(path.strip).so_files
  rescue Errno::ENOENT
    next
  end
end

if opt['path'] and ENV['PATH']
  ENV['PATH'].split(":").each do |path|
    so_files.merge Pathname.new(path).so_files(false)
  end
end

db = SQLite3::Database.new( opt['output'] ? opt['output'] : 'symbols-datatabase.sqlite' )
db.execute("CREATE TABLE symbols ( path, symbol, abi )")

so_files.each do |so|
  local_suppressions = $partial_suppressions.dup.delete_if { |s| not so.to_s =~ s[0] }

  begin
    Elf::File.open(so) do |elf|
      abi = "#{elf.elf_class} #{elf.abi} #{elf.machine}"

      elf.sections['.dynsym'].symbols.each do |sym|
        begin
          next if sym.idx == 0
          next if sym.bind != Elf::Symbol::Binding::Global
          next if sym.section == nil
          next if sym.value == 0
          next if sym.section.is_a? Integer
          next if sym.section.name == '.init'

          symbol = sym.name
          
          local_suppressions.each do |supp|
            if symbol =~ supp[1]
              symbol = nil
              break
            end
          end

          next if symbol == nil

          # Get the symbol version afterward, suppressions act on the single symbols
          version_idx = elf.sections['.gnu.version'][sym.idx] if elf.sections['.gnu.version']
          if version_idx and version_idx >= 2
            name_idx = (version_idx & (1 << 15) == 0 ? 0 : 1)
            version_idx = version_idx & ~(1 << 15)

            version_name = elf.sections['.gnu.version_d'][version_idx][:names][name_idx]

            symbol = "#{symbol}@@#{version_name}"
          end

          db.execute("INSERT INTO symbols VALUES('#{so}', '#{symbol}', '#{abi}')")
        rescue Exception
          $stderr.puts "Mangling symbol #{sym.name}"
          raise
        end
      end
    end
  rescue Elf::File::NotAnELF
    next
  rescue Exception
    $stderr.puts "Checking #{so}"
    raise
  end
end
