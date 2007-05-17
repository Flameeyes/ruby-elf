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

require 'set'
require 'sqlite3'
require 'pathname'
require 'tmpdir'
require 'elf'

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
    line.strip!
    path, symbols = line.split(/\s+/, 2)

    if not symbols or symbols == ""
      $total_suppressions << Regexp.new(path)
    else
      $partial_suppressions << [Regexp.new(path), Regexp.new(symbols)]
    end
  end
end

ldso_paths = Set.new
ldso_paths.merge ENV['LD_LIBRARY_PATH'].split(":").set if ENV['LD_LIBRARY_PATH']

ldconfig_paths = File.new("/etc/ld.so.conf").readlines
ldconfig_paths.delete_if { |l| l =~ /\s*#.*/ }

ldso_paths.merge ldconfig_paths

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

if ENV['PATH']
  ENV['PATH'].split(":").each do |path|
    so_files.merge Pathname.new(path).so_files(false)
  end
end

db = SQLite3::Database.new("#{Dir.tmpdir}/link-conflicts-tmp.db")
db.execute("CREATE TABLE symbols ( path, symbol, abi )")

so_files.each do |so|
  local_suppressions = $partial_suppressions.dup.delete_if { |s| not so.to_s =~ s[0] }
  
  begin
    f = Elf::File.new(so)
    abi = "#{f.elf_class} #{f.abi} #{f.machine}"

    f.sections['.dynsym'].symbols.each do |sym|
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
        version_idx = f.sections['.gnu.version'][sym.idx] if f.sections['.gnu.version']
        if version_idx and version_idx >= 2
          name_idx = (version_idx & (1 << 15) == 0 ? 0 : 1)
          version_idx = version_idx & ~(1 << 15)

          version_name = f.sections['.gnu.version_d'][version_idx][:names][name_idx]

          symbol = "#{symbol}@@#{version_name}"
        end

        db.execute("INSERT INTO symbols VALUES('#{so}', '#{symbol}', '#{abi}')")
      rescue Exception
        $stderr.puts "Mangling symbol #{sym.name}"
        raise
      end
    end

    f.close
  rescue Elf::File::NotAnELF
    next
  rescue Exception
    $stderr.puts "Checking #{so}"
    f.close if f
    raise
  end
end

db.execute "SELECT * FROM ( SELECT symbol, abi, COUNT(*) AS occurrences FROM symbols GROUP BY symbol, abi ) WHERE occurrences > 1 ORDER BY occurrences DESC;" do |row|
  puts "Symbol #{row[0]} (#{row[1]}) present #{row[2]} times"
  db.execute( "SELECT path FROM symbols WHERE symbol='#{row[0]}' AND abi = '#{row[1]}'" ) do |path|
    puts "  #{path[0]}"
  end
end
