#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Copyright © 2007-2010 Diego E. "Flameeyes" Pettenò <flameeyes@gmail.com>
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

require 'getoptlong'
require 'set'
require 'pathname'
require 'pg'

require 'elf'
require 'elf/utils/loader'

opts = GetoptLong.new(
  ["--no-scan-ldpath",     "-L", GetoptLong::NO_ARGUMENT ],
  ["--scan-path",          "-p", GetoptLong::NO_ARGUMENT ],
  ["--suppressions",       "-s", GetoptLong::REQUIRED_ARGUMENT ],
  ["--multiplementations", "-m", GetoptLong::REQUIRED_ARGUMENT ],
  ["--scan-directory",     "-d", GetoptLong::REQUIRED_ARGUMENT ],
  ["--recursive-scan",     "-r", GetoptLong::NO_ARGUMENT ],
  ["--elf-machine",        "-M", GetoptLong::REQUIRED_ARGUMENT ],
  ["--postgres-username",  "-U", GetoptLong::REQUIRED_ARGUMENT ],
  ["--postgres-password",  "-P", GetoptLong::REQUIRED_ARGUMENT ],
  ["--postgres-hostname",  "-H", GetoptLong::REQUIRED_ARGUMENT ],
  ["--postgres-port",      "-T",  GetoptLong::REQUIRED_ARGUMENT ],
  ["--postgres-database",  "-D", GetoptLong::REQUIRED_ARGUMENT ]
)

suppression_files = File.exist?('suppressions') ? [ 'suppressions' ] : []
multimplementation_files = File.exist?('multimplementations') ? [ 'multimplementations' ] : []
scan_path = false
scan_ldpath = true
recursive_scan = false
scan_directories = []
$machines = []

pg_params = {}

opts.each do |opt, arg|
  case opt
  when '--suppressions'
    unless File.exist? arg
      $stderr.puts "harvest.rb: no such file or directory - #{arg}"
      exit -1
    end
    suppression_files << arg
  when "--multiplementations"
    unless File.exist? arg
      $stderr.puts "harvest.rb: no such file or directory - #{arg}"
      exit -1
    end
    multimplementation_files << arg
  when '--scan-path'
    scan_path = true
  when '--no-scan-ldpath'
    scan_ldpath = false
  when '--scan-directory'
    scan_directories << arg
  when '--recursive-scan'
    recursive_scan = true
  when "--elf-machine"
    machine_str = arg.dup

    # Remove the EM_ prefix if present
    machine_str = machine_str[3..-1] if arg[0..2].upcase == "EM_"

    # Remove underscores if present (we don't keep them in our
    # constants)
    machine_str.delete!("_")

    machine_val = Elf::Machine.from_string(machine_str)

    if machine_val.nil?
      $stderr.puts "harvest.rb: unknown machine string - #{arg}"
    else
      $machines << machine_val unless machine_val.nil?
    end
  when '--postgres-username' then pg_params[:user] = arg
  when '--postgres-password' then pg_params[:password] = arg
  when '--postgres-hostname' then pg_params[:host] = arg
  when '--postgres-port'     then pg_params[:port] = arg
  when '--postgres-database' then pg_params[:dbname] = arg
  end
end

$machines = nil if $machines.empty?

db = PGconn.open(pg_params)

db.exec("DROP TABLE IF EXISTS symbols, multimplementations, objects CASCADE")

db.exec("CREATE TABLE objects ( id INTEGER PRIMARY KEY, name VARCHAR(4096), abi VARCHAR(255), UNIQUE(name, abi) )")
db.exec("CREATE TABLE multimplementations ( id INTEGER REFERENCES objects(id) ON DELETE CASCADE, path VARCHAR(4096), UNIQUE(path) )")
db.exec("CREATE TABLE symbols ( object INTEGER REFERENCES objects(id) ON DELETE CASCADE, symbol TEXT,
         PRIMARY KEY(object, symbol) )")

db.exec("CREATE VIEW symbol_count AS
         SELECT symbol, abi, COUNT(*) AS occurrences FROM symbols INNER JOIN objects ON symbols.object = objects.id GROUP BY symbol, abi")
db.exec("CREATE VIEW duplicate_symbols AS
         SELECT * FROM symbol_count WHERE occurrences > 1 ORDER BY occurrences DESC, symbol ASC")

db.exec("PREPARE newmulti (int, text) AS
         INSERT INTO multimplementations (id, path) VALUES($1, $2)")
db.exec("PREPARE newobject (int, text, text) AS
         INSERT INTO objects(id, name, abi) VALUES($1, $2, $3)")
db.exec("PREPARE newsymbol (int, text) AS
         INSERT INTO symbols VALUES($1, $2)")

db.exec("PREPARE checkimplementation(text, text) AS
         SELECT id FROM objects WHERE name = $1 AND abi = $2")
db.exec("PREPARE checkdupsymbol (int, text) AS
         SELECT 1 FROM symbols WHERE object = $1 AND symbol = $2")

# Total suppressions are for directories to skip entirely
# Partial suppressions are the ones that apply only to a subset
# of symbols.
$total_suppressions = []
$partial_suppressions = []

suppression_files.each do |suppression|
  File.open(suppression) do |file|
    file.each_line do |line|
      path, symbols = line.
        gsub(/#\s.*/, '').
        strip.
        split(/\s+/, 2)
      
      next unless path
      
      if not symbols or symbols == ""
        $total_suppressions << Regexp.new(path)
      else
        $partial_suppressions << [Regexp.new(path), Regexp.new(symbols)]
      end
    end
  end
end

multimplementations = []

multimplementation_files.each do |multimplementation|
  File.open(multimplementation) do |file|
    file.each_line do |line|
      implementation, paths = line.
        gsub(/#\s.*/, '').
        strip.
        split(/\s+/, 2)

      next unless implementation
      next unless paths
      
      multimplementations << [ implementation, Regexp.new(paths) ]
    end
  end
end

so_files = Set.new

# Extend Pathname with a so_files method
class Pathname
  def maybe_queue
    return nil if symlink?

    $total_suppressions.each do |supp|
      return nil if to_s =~ supp
    end

    elf = nil

    begin
      elf = Elf::File.open(self)

      if ($machines.nil? or $machines.include?(elf.machine)) and
          (elf.has_section?('.dynsym') and elf.has_section?('.dynstr'))

        return to_s
      else
        return nil
      end
    # Explicitly list this so that it won't pollute the output
    rescue Elf::File::NotAnELF
      return nil
    rescue Exception => e
      $stderr.puts "harvest.rb: #{e.message} - #{self.to_s}"
    ensure
      elf.close unless elf.nil?
    end
  end

  def so_files(recursive = true)
    res = Set.new
    children.each do |entry|
      begin
        case entry.ftype
        when "directory"
          res.merge entry.so_files if recursive
        when "file"
          res << entry.maybe_queue
        end
        # When using C-c to stop, well, stop.
      rescue Interrupt
        raise
      rescue Exception => e
        $stderr.puts "Ignoring #{entry} (#{e.message})"
        next
      end
    end

    return res
  end
end

if scan_ldpath
  Elf::Utilities.system_library_path.each do |path|
    begin
      so_files.merge Pathname.new(path).so_files
    rescue Errno::ENOENT
      $stderr.puts "harvest.rb: No such file or directory - #{path}"
      next
    end
  end
end

if scan_path and ENV['PATH']
  ENV['PATH'].split(":").each do |path|
    begin
      so_files.merge Pathname.new(path).so_files(false)
    rescue Errno::ENOENT
      $stderr.puts "harvest.rb: No such file or directory - #{path}"
      next
    end
  end
end

scan_directories.each do |path|
  begin
    so_files.merge Pathname.new(path).so_files(recursive_scan)
  rescue Errno::ENOENT
    $stderr.puts "harvest.rb: No such file or directory - #{path}"
    next
  end
end

# if there are explicit files listed in the standard input, scan those
# right away.
ARGV.each do |path|
  so_files << Pathname.new(path).maybe_queue
end

# finally if none of the above matched, try checking for data on the
# standard input
if ARGV.size == 0 and not scan_path and scan_directories.size == 0
  $stdin.each_line do |path|
    so_files << Pathname.new(path.chomp("\n")).maybe_queue
  end
end

so_files.delete(nil)

db.exec("BEGIN TRANSACTION")
val = 0

begin
  require 'progressbar'

  pbar = ProgressBar.new("harvest", so_files.size)
rescue LoadError, NameError
end

so_files.each do |so|
  local_suppressions = $partial_suppressions.dup.delete_if { |s| not so.to_s =~ s[0] }

  begin
    Elf::File.open(so) do |elf|
      name = so
      abi = "#{elf.elf_class} #{elf.abi} #{elf.machine.to_s.gsub("'", "\\'" )}"

      impid = nil

      multimplementations.each do |implementation, paths|
        # Get the full matchdata because we might need to get the matches.
        match = paths.match(so)

        next unless match

        while implementation =~ /\$([0-9]+)/ do
          match_idx = $1.to_i
          replacement = match[match_idx]
          replacement = "" if replacement.nil?
          implementation = implementation.gsub("$#{match_idx}", replacement)
        end

        name = implementation
        db.exec("EXECUTE checkimplementation('#{implementation}', '#{abi}')").each do |row|
          impid = row['id']
        end
        break
      end

      unless impid
        val += 1
        impid = val
        
        db.exec("EXECUTE newobject(#{impid}, '#{name}', '#{abi}')")
      end

      db.exec("EXECUTE newmulti(#{impid}, '#{so}')") if so != name
        
      elf['.dynsym'].each do |sym|
        begin
          next if sym.idx == 0 or
            sym.bind != Elf::Symbol::Binding::Global or
            sym.section.nil? or
            sym.value == 0 or
            sym.section.is_a? Integer or
            sym.section.name == '.init' or
            sym.section.name == '.bss'

          skip = false
          
          local_suppressions.each do |supp|
            if sym.name =~ supp[1]
              skip = true
              break
            end
          end

          next if skip or (db.exec("EXECUTE checkdupsymbol('#{impid}', '#{sym.name}@#{sym.version}')").num_tuples > 0)

          db.exec("EXECUTE newsymbol('#{impid}', '#{sym.name}@#{sym.version}')")
          
        rescue Exception
          $stderr.puts "Mangling symbol #{sym.name}"
          raise
        end
      end
    end
  rescue Exception
    $stderr.puts "Checking #{so}"
    raise
  end

  pbar.inc if pbar
end

db.exec("CREATE INDEX objects_name ON objects(name)")
db.exec("CREATE INDEX symbols_symbol ON symbols(symbol)")
db.exec("COMMIT")
