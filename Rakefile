# -*- coding: utf-8 -*-

# Ensure that the lib/ directory is used before the one installed in
# the system to get the right version, then require the library
# itself.
$:.insert(0, File.expand_path("../#{file}/lib", __FILE__))
require 'elf'

FileList["tasks/*.rb"].sort.each do |file|
  require File.expand_path("../#{file}", __FILE__)
end

task :default => [:test]

# Local Variables:
# mode: ruby
# mode: flyspell-prog
# ispell-local-dictionary: "english"
# End:
