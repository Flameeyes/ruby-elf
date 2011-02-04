# -*- coding: utf-8 -*-

# Ensure that the lib/ directory is used before the one installed in
# the system to get the right version, then require the library
# itself.
$:.insert(0, File.expand_path("../#{file}/lib", __FILE__))
require 'elf'

FileList["tasks/*.rb"].sort.each do |file|
  require file
end

task :default => [:test]

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = ['tests/ts_rubyelf.rb']
end

task :test => [:demanglers]

begin
  require 'rcov/rcovtask'
  
  Rcov::RcovTask.new do |t|
    t.test_files = ['tests/ts_rubyelf.rb']
  end

  task :rcov => [:demanglers]
rescue LoadError
  $stderr.puts "Unable to find rcov, coverage won't be available"
end

# Local Variables:
# mode: ruby
# mode: flyspell-prog
# ispell-local-dictionary: "english"
# End:
