# -*- ruby -*- coding: utf-8 -*-
$:.unshift(File.dirname(__FILE__) + '/lib')
require 'elf'

Gem::Specification.new do |s|
  s.name = 'ruby-elf'
  s.version = Elf::VERSION
  s.summary = "Pure Ruby ELF file parser and utilities"

  s.requirements << 'none'
  s.require_path = 'lib'
  s.homepage = "http://www.flameeyes.eu/projects/ruby-elf"
  s.license = "GPL-2 or later"
  s.author = "Diego Elio Pettenò"
  s.email = "flameeyes@flameeyes.eu"

  s.description = <<EOF
Ruby-Elf is a pure-Ruby library for parse and fetch information about
ELF format used by Linux, FreeBSD, Solaris and other Unix-like
operating systems, and include a set of analysis tools helpful for
both optimisations and verification of compiled ELF files.
EOF

  s.files  = %w{COPYING README.md DONATING ruby-elf.gemspec}
  s.files += Dir['lib/**/*.rb']
  s.files += Dir['bin/**/*.rb']
  s.files += Dir['tools/**/*.rb']
  s.files += Dir['manpages/*.1']
end
