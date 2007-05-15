#!/usr/bin/env ruby

require 'set'
require 'sqlite3'
require 'pathname'

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
  def so_files
    res = Set.new
    each_entry do |entry|
      begin
        next if entry.to_s =~ /\.\.?$/
        entry = self + entry

        skip = false

        $total_suppressions.each do |supp|
          if entry.to_s =~ supp
            skip = true
            break
          end
        end

        next if skip
        
        if entry.directory?
          res.merge entry.so_files
          next
        elsif entry.to_s[-3..-1] == ".so"
          res.add entry.realpath.to_s
        end
      rescue Errno::EACCES
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

db = SQLite3::Database.new("/tmp/link-conficts-tmp.db")
db.execute("CREATE TABLE symbols ( path, symbol )")

so_files.each do |so|
  # TODO: nm does not provide symbols' version information
  # this call should really be replaced with some kind of
  # libelf bindings
  `readelf -sW #{so}`.each_line do |re_line|
    re_line = re_line.split(/\s+/)

    next if re_line[5] != "GLOBAL"
    next if re_line[7] == "UND"

    symbol = re_line[8]
    
    $partial_suppressions.each do |supp|
      next unless so.to_s =~ supp[0]

      if symbol =~ supp[1]
        symbol = nil
        break
      end
    end

    next if symbol == nil

    $stderr.puts "INSERT INTO symbols VALUES('#{so}', '#{symbol}')"
    db.execute("INSERT INTO symbols VALUES('#{so}', '#{symbol}')")
  end
end

search_files = db.prepare( "SELECT path FROM symbols WHERE symbol='?'")

db.execute "SELECT * FROM ( SELECT symbol, COUNT(*) AS occurrences FROM symbols GROUP BY symbol ) WHERE occurrences > 1 ORDER BY occurrences DESC;" do |row|
  puts "Symbol #{row[0]} present #{row[1]}"
  search_files.execute(row[0]) do |path|
    puts "  #{path}"
  end
end
