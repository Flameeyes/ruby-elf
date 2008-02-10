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
require 'sqlite3'
require 'elf'

opts = GetoptLong.new(
  ["--output",             "-o", GetoptLong::REQUIRED_ARGUMENT ],
  ["--no-scan-ldpath",     "-L", GetoptLong::NO_ARGUMENT ],
  ["--scan-path",          "-p", GetoptLong::NO_ARGUMENT ],
  ["--suppressions",       "-s", GetoptLong::REQUIRED_ARGUMENT ],
  ["--multiplementations", "-m", GetoptLong::REQUIRED_ARGUMENT ],
  ["--scan-directory",     "-d", GetoptLong::REQUIRED_ARGUMENT ],
  ["--rescursive-scan",    "-r", GetoptLong::NO_ARGUMENT ]
)

output_file = 'symbols-database.sqlite3'
suppression_files = File.exist?('suppressions') ? [ 'suppressions' ] : []
multimplementation_files = File.exist?('multimplementations') ? [ 'multimplementations' ] : []
scan_path = false
scan_ldpath = true
recursive_scan = false
scan_directories = []

opts.each do |opt, arg|
  case opt
  when '--output'
    output_file = arg
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

db = SQLite3::Database.new output_file
db.execute("BEGIN TRANSACTION")
db.execute("CREATE TABLE objects ( id INTEGER PRIMARY KEY, path, abi, soname )")
db.execute("CREATE TABLE symbols ( object INTEGER, symbol, UNIQUE(object, symbol) )")

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
        db.execute("SELECT id FROM objects WHERE path = '#{implementation}'") do |row|
          impid = row[0]
        end
        break
      end

      unless impid
        val += 1
        impid = val
        
        db.execute("INSERT INTO objects(id, path, abi, soname) VALUES(#{impid}, '#{so}', '#{elf.elf_class} #{elf.abi} #{elf.machine}', '#{soname}')")
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

          next if skip
          
          begin
            db.execute("INSERT INTO symbols VALUES('#{impid}', '#{sym.name}@@#{sym.version}')")
          # Duplicated unique constraint causes this exception to be raised.
          # unfortunately we're going to ignore some other errors this way
          # but until I decide to write this with a different DBMS I'm afraid
          # it's the only way.
          rescue SQLite3::SQLException => e
            raise unless e.message == "SQL logic error or missing database"
            next
          end
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

db.execute("COMMIT")