#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Copyright © 2007-2010 Diego Elio Pettenò <flameeyes@flameeyes.eu>
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
require 'elf/tools'

module Elf::Tools
  class CollisionsHarvester < Elf::Tool
    def self.initialize
      super
      # this script doesn't support running multithreaded, since we
      # need synchronous access to the database itself, so for now
      # simply make sure that it never is executed with threads.
      @execution_threads = nil

      @options |= [
                   ["--no-scan-ldpath",      "-L", GetoptLong::NO_ARGUMENT ],
                   ["--scan-path",           "-p", GetoptLong::NO_ARGUMENT ],
                   ["--suppressions",        "-s", GetoptLong::REQUIRED_ARGUMENT ],
                   ["--multimplementations", "-m", GetoptLong::REQUIRED_ARGUMENT ],
                   ["--elf-machine",         "-M", GetoptLong::REQUIRED_ARGUMENT ],
                   ["--postgres-username",   "-U", GetoptLong::REQUIRED_ARGUMENT ],
                   ["--postgres-password",   "-P", GetoptLong::REQUIRED_ARGUMENT ],
                   ["--postgres-hostname",   "-H", GetoptLong::REQUIRED_ARGUMENT ],
                   ["--postgres-port",       "-T", GetoptLong::REQUIRED_ARGUMENT ],
                   ["--postgres-database",   "-D", GetoptLong::REQUIRED_ARGUMENT ],
                   ["--output",              "-o", GetoptLong::REQUIRED_ARGUMENT ],
                   ["--analyze-only",        "-A", GetoptLong::NO_ARGUMENT ],
                  ]

      # we remove the -R option since we always want to be recursive in our search
      @options.delete_if { |opt| opt[1] == "-R" }
      @recursive = true
      @analyze_only = false

      @suppression_files = File.exist?('suppressions') ? [ 'suppressions' ] : []
      @multimplementation_files = File.exist?('multimplementations') ? [ 'multimplementations' ] : []

      # Total suppressions are for directories to skip entirely
      # Partial suppressions are the ones that apply only to a subset
      # of symbols.
      @total_suppressions = []
      @partial_suppressions = []

      @multimplementations = []

      @output = "collisions.log"
    end

    def self.suppressions_cb(arg)
      unless File.exist? arg
        puterror("no such file or directory - #{arg}")
        exit -1
      end
      @suppression_files << arg
    end

    def self.multimplementations_cb(arg)
      unless File.exist? arg
        puterror("no such file or directory - #{arg}")
        exit -1
      end
      @multimplementation_files << arg
    end

    def self.elf_machine_cb(arg)
      machine_str = (arg[0..2].upcase == "EM_" ? arg[3..-1] : arg).delete("_")
      machine_val = Elf::Machine.from_string(machine_str)

      if machine_val.nil?
        puterror("unknown machine string - #{arg}")
      else
        @machines ||= []
        @machines << machine_val
      end
    end

    def self.after_options
      pg_params = {
        :dbname   => @postgres_database,
        :host     => @postgres_hostname,
        :password => @postgres_password,
        :port     => @postgres_port,
        :user     => @postgres_username,
      }

      @suppression_files.each do |suppression|
        File.open(suppression) do |file|
          file.each_line do |line|
            path, symbols = line.
              gsub(/#\s.*/, '').
              strip.
              split(/\s+/, 2)

            next unless path

            if not symbols or symbols == ""
              @total_suppressions << Regexp.new(path)
            else
              @partial_suppressions << [Regexp.new(path), Regexp.new(symbols)]
            end
          end
        end
      end

      @total_suppressions = Regexp.union(@total_suppressions)

      @multimplementation_files.each do |multimplementation|
        @multimplementations |= \
        File.read(multimplementation).split(/\r?\n/).collect do |line|
          implementation, paths = line.
            gsub(/#\s.*/, '').
            strip.
            split(/\s+/, 2)

          next if (implementation.nil? or paths.nil?)

          [ implementation, Regexp.new(paths) ]
        end
      end
      @multimplementations.delete_if { |x| x.nil? }

      @targets |=
        ( !@no_scan_ldpath             ? Elf::Utilities.system_library_path : [] ) |
        ( (@scan_path and ENV['PATH']) ? ENV['PATH'].split(":")             : [] )

      return if @analyse_only

      @db = PGconn.open(pg_params)

      @db.exec(<<EOF)
BEGIN TRANSACTION;

DROP TABLE IF EXISTS symbols, multimplementations, objects CASCADE;
DROP EXTENSION IF EXISTS plpgsql CASCADE;

CREATE EXTENSION plpgsql;
CREATE TABLE objects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(4096),
    abi VARCHAR(255),
    exported BOOLEAN,
    UNIQUE(name, abi)
);
CREATE TABLE multimplementations (
    id INTEGER REFERENCES objects(id) ON DELETE CASCADE,
    path VARCHAR(4096),
    UNIQUE(path)
);
CREATE TABLE symbols (
    object INTEGER REFERENCES objects(id) ON DELETE CASCADE,
    symbol TEXT,
    PRIMARY KEY(object, symbol)
);

CREATE VIEW symbol_count AS
   SELECT symbol, abi, COUNT(*) AS occurrences, BOOL_OR(objects.exported) AS exported
     FROM symbols INNER JOIN objects ON symbols.object = objects.id GROUP BY symbol, abi;
CREATE VIEW duplicate_symbols AS
   SELECT * FROM symbol_count
     WHERE occurrences > 1 AND exported = 't'
     ORDER BY occurrences DESC, symbol ASC;

PREPARE getinstances (text, text) AS
   SELECT name FROM symbols INNER JOIN objects ON symbols.object = objects.id
      WHERE symbol = $1 AND abi = $2 ORDER BY name;

CREATE FUNCTION implementation (
    p_implementation TEXT,
    p_abi TEXT,
    p_exported BOOLEAN,
    OUT implementation_id INTEGER,
    OUT created BOOLEAN
) AS $$
  BEGIN
    SELECT INTO implementation_id id FROM objects
      WHERE name = p_implementation AND abi = p_abi;

    IF implementation_id IS NULL THEN
      created := TRUE;

      INSERT INTO objects(name, abi, exported)
        VALUES(p_implementation, p_abi, p_exported);
      SELECT INTO implementation_id
        currval(pg_get_serial_sequence('objects', 'id'));
    END IF;
  END;
$$ LANGUAGE 'plpgsql';

CREATE FUNCTION multimplementation (
  p_id INTEGER,
  p_filepath TEXT
) RETURNS BOOLEAN AS $$
  BEGIN
    INSERT INTO multimplementations (id, path) VALUES(p_id, p_filepath);
    RETURN 't';
  EXCEPTION
    WHEN unique_violation THEN
      RETURN 'f';
  END;
$$ LANGUAGE 'plpgsql';

CREATE FUNCTION symbol (
    p_object INTEGER,
    p_symbol TEXT
) RETURNS VOID AS '
  BEGIN
    INSERT INTO symbols VALUES(p_object, p_symbol);
    RETURN;
  EXCEPTION
    WHEN unique_violation THEN
      RETURN;
  END;
' LANGUAGE 'plpgsql';

COMMIT;
EOF
    end

    def self.db_exec(query)
      @db.exec(query)
    end

    def self.analysis(filename)
      return if filename =~ @total_suppressions

      begin
        Elf::File.open(filename) do |elf|
          unless ($machines.nil? or $machines.include?(elf.machine)) and
              (elf.has_section?('.dynsym') and elf.has_section?('.dynstr') and
               elf.has_section?('.dynamic')) and
              (elf[".dynsym"].class == Elf::SymbolTable)
            return
          end

          local_suppressions = Regexp.union((@partial_suppressions.dup.delete_if{ |s| filename.to_s !~ s[0] }).collect { |s| s[1] })

          name = filename
          abi = "#{elf.elf_class} #{elf.abi} #{elf.machine}".gsub("'", "''")

          @multimplementations.each do |implementation, paths|
            # Get the full matchdata because we might need to get the matches.
            match = paths.match(filename)

            next unless match

            while implementation =~ /\$([0-9]+)/ do
              match_idx = $1.to_i
              replacement = match[match_idx]
              replacement = "" if replacement.nil?
              implementation = implementation.gsub("$#{match_idx}", replacement)
            end

            name = implementation
            break
          end

          shared = (filename != name) || (elf['.dynamic'].soname != nil)

          res = db_exec("SELECT * FROM implementation('#{name}', '#{abi}', '#{shared}')")
          impid = res[0]["implementation_id"]

          if filename != name
            # If this is a collapsed multimplementation, add it to the list
            res = db_exec("SELECT multimplementation(#{impid}, '#{filename}') AS created");
          end

          # skip over the file if we already visited it (either directly
          # or as a multimplementation.
          next if res[0]["created"] != "t"

          query = ""
          elf['.dynsym'].each do |sym|
            begin
              next if sym.idx == 0 or
                sym.bind != Elf::Symbol::Binding::Global or
                sym.section.nil? or
                sym.value == 0 or
                sym.section.is_a? Integer or
                sym.section.name == '.init' or
                sym.section.name == '.bss'

              next if (sym.name =~ local_suppressions);

              query << "SELECT symbol('#{impid}', '#{sym.name}@#{sym.version}');"
            rescue Exception
              $stderr.puts "Mangling symbol #{sym.name}"
              raise
            end
          end
          db_exec("BEGIN TRANSACTION;" + query + "COMMIT;") unless query.empty?
        end
      rescue Exception => e
        putnotice "#{filename}: #{e.message}"
      end
    end

    def self.results
      db_exec(<<EOF)
BEGIN TRANSACTION;
CREATE INDEX objects_name ON objects(name);
CREATE INDEX symbols_symbol ON symbols(symbol);
COMMIT;
EOF

      outfile = File.new(@output, "w")

      db_exec("SELECT * FROM duplicate_symbols").each do |row|
        outfile.puts "Symbol #{row['symbol']} (#{row['abi']}) present #{row['occurrences']} times"
        db_exec( "EXECUTE getinstances ('#{row['symbol']}', '#{row['abi'].gsub("'", "''")}')" ).each do |path|
          outfile.puts "  #{path['name']}"
        end
      end
    end
  end
end
