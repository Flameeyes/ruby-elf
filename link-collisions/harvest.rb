#!/usr/bin/env ruby
# Copyright © 2007-2008, Diego "Flameeyes" Pettenò <flameeyes@gmail.com>
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
require 'postgres'
require 'elf'

opts = GetoptLong.new(
  ["--no-scan-ldpath",     "-L", GetoptLong::NO_ARGUMENT ],
  ["--scan-path",          "-p", GetoptLong::NO_ARGUMENT ],
  ["--suppressions",       "-s", GetoptLong::REQUIRED_ARGUMENT ],
  ["--multiplementations", "-m", GetoptLong::REQUIRED_ARGUMENT ],
  ["--scan-directory",     "-d", GetoptLong::REQUIRED_ARGUMENT ],
  ["--rescursive-scan",    "-r", GetoptLong::NO_ARGUMENT ],
  ["--postgres-username",  "-U", GetoptLong::REQUIRED_ARGUMENT ],
  ["--postgres-password",  "-P", GetoptLong::REQUIRED_ARGUMENT ],
  ["--postgres-database",  "-D", GetoptLong::REQUIRED_ARGUMENT ]
)

suppression_files = File.exist?('suppressions') ? [ 'suppressions' ] : []
multimplementation_files = File.exist?('multimplementations') ? [ 'multimplementations' ] : []
scan_path = false
scan_ldpath = true
recursive_scan = false
scan_directories = []

pg_username = nil
pg_password = nil
pg_database = nil

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
  when '--postgres-username' then pg_username = arg
  when '--postgres-password' then pg_password = arg
  when '--postgres-database' then pg_database = arg
  end
end

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
        strip!.
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
        strip!.
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
        elsif entry.symlink?
          next
        else
          begin
            elf = Elf::File.open(entry)
            elf.close
            res.add entry.to_s
          rescue Elf::File::NotAnELF
            next
          rescue Exception => e
            $stderr.puts "Scanning #{entry}"
            raise e
          end
        end
      rescue Errno::EACCES, Errno::ENOENT
        next
      end
    end

    return res
  end
end

if scan_ldpath
  ldso_paths = Set.new
  ldso_paths.merge ENV['LD_LIBRARY_PATH'].split(":").set if ENV['LD_LIBRARY_PATH']
  
  File.open("/etc/ld.so.conf") do |ldsoconf|
    ldso_paths.merge ldsoconf.readlines.
      delete_if { |l| l =~ /\s*#.*/ }.
      collect { |l| l.strip }.
      uniq
  end

  ldso_paths.each do |path|
    begin
      so_files.merge Pathname.new(path.strip).so_files
    rescue Errno::ENOENT
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

db = PGconn.open('user' => pg_username, 'password' => pg_password, 'dbname' => pg_database)

db.exec("DROP VIEW duplicate_symbols") rescue PGError
db.exec("DROP VIEW symbol_count") rescue PGError
db.exec("DROP TABLE symbols") rescue PGError
db.exec("DROP TABLE objects") rescue PGError

db.exec("CREATE TABLE objects ( id INTEGER PRIMARY KEY, path VARCHAR(4096), abi VARCHAR(255), soname VARCHAR(255), UNIQUE(path) )")
db.exec("CREATE TABLE symbols ( object INTEGER REFERENCES objects(id), symbol TEXT, PRIMARY KEY(object, symbol) )")

db.exec("CREATE VIEW symbol_count AS
         SELECT symbol, abi, COUNT(*) AS occurrences FROM symbols INNER JOIN objects ON symbols.object = objects.id GROUP BY symbol, abi")
db.exec("CREATE VIEW duplicate_symbols AS
         SELECT * FROM symbol_count WHERE occurrences > 1 ORDER BY occurrences DESC")

db.exec("PREPARE newobject (int, text, text, text) AS
         INSERT INTO objects(id, path, abi, soname) VALUES($1, $2, $3, $4)")
db.exec("PREPARE newsymbol (int, text) AS
         INSERT INTO symbols VALUES($1, $2)")
db.exec("PREPARE checkimplementation(text) AS
         SELECT id FROM objects WHERE path = $1")
db.exec("PREPARE checkdupsymbol (int, text) AS
         SELECT 1 FROM symbols WHERE object = $1 AND symbol = $2")

db.exec("BEGIN TRANSACTION")
val = 0

so_files.each do |so|
  local_suppressions = $partial_suppressions.dup.delete_if { |s| not so.to_s =~ s[0] }

  begin
    Elf::File.open(so) do |elf|
      next unless elf.sections['.dynsym'] and elf.sections['.dynstr']

      abi = "#{elf.elf_class} #{elf.abi} #{elf.machine}"
      soname = ""

      if elf.sections['.dynamic']
        elf.sections['.dynamic'].entries.each do |entry|
          case entry[:type]
          when Elf::Dynamic::Type::SoName
            soname = elf.sections['.dynstr'][entry[:attribute]]
          end
        end
      end

      impid = nil

      multimplementations.each do |implementation, paths|
        next unless so =~ paths

        so = implementation
        db.exec("EXECUTE checkimplementation('#{implementation}')").each do |row|
          impid = row[0]
        end
        break
      end

      unless impid
        val += 1
        impid = val
        
        db.exec("EXECUTE newobject(#{impid}, '#{so}', '#{elf.elf_class} #{elf.abi} #{elf.machine.to_s.gsub("'", "\\'" )}', '#{soname}')")
      end
        
      elf.sections['.dynsym'].symbols.each do |sym|
        begin
          next if sym.idx == 0 or
            sym.bind != Elf::Symbol::Binding::Global or
            sym.section == nil or
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

          next if skip or (db.exec("EXECUTE checkdupsymbol('#{impid}', '#{sym.name}@@#{sym.version}')").num_tuples > 0)

          db.exec("EXECUTE newsymbol('#{impid}', '#{sym.name}@@#{sym.version}')")
          
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

db.exec("COMMIT")
