# -*- coding: utf-8 -*-
# Ensure that the lib/ directory is present
$:.insert(0, File.expand_path("../#{file}/lib", __FILE__))
require 'elf'

task :default => [:test]

rule '.rb' => '.rl' do |t|
  sh "ragel", "-R", "-o", t.name, t.source
end

desc "Build the Ruby demanglers based on the Ragel code"
task :demanglers => FileList["lib/elf/symbol/demangler_*.rl"].collect { |file|
  file.sub(/\.rl$/, ".rb")
}

XSL_NS_ROOT="http://docbook.sourceforge.net/release/xsl-ns/current"

rule '.1' => [ '.1.xml' ] + FileList["manpages/*.xmli"] do |t|
  sh "xsltproc", "--stringparam", "man.copyright.section.enabled", "0", \
  "--xinclude", "-o", t.name, "#{XSL_NS_ROOT}/manpages/docbook.xsl", \
  t.source
end

desc "Build the man pages for the installed tools"
task :manpages => FileList["manpages/*.1.xml"].collect { |file|
  file.sub(/\.1\.xml$/, ".1")
}

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

Spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "Pure Ruby ELF file parser and utilities"
  s.name = "ruby-elf"
  s.version = Elf::VERSION
  s.requirements << 'none'
  s.require_path = 'lib'
  s.rubyforge_project = "ruby-elf"
  s.homepage = "http://www.flameeyes.eu/projects/ruby-elf"
  s.license = "GPL-2 or later"
  s.author = "Diego Elio Pettenò"
  s.email = "flameeyes@gmail.com"

  s.files = IO.popen("git ls-files").lines.collect do |line|
    next if line =~ /^(\.gitignore$|tests\/|.*\.xmli$)/
    line.strip.sub(/\.1\.xml$/, '.1')
  end

  s.executables = FileList["bin/*"].collect { |bin|
    next if bin =~ /~$/
    bin.sub(/^bin\//, '')
  }

  s.description = <<EOF
Ruby-Elf is a pure-Ruby library for parse and fetch information about
ELF format used by Linux, FreeBSD, Solaris and other Unix-like
operating systems, and include a set of analysis tools helpful for
both optimisations and verification of compiled ELF files.
EOF
end

file "ruby-elf-#{Elf::VERSION}.gemspec" => "Rakefile" do |t|
  File.new(t.name, "w").write Spec.to_ruby
end

require 'rake/packagetask'
Rake::PackageTask.new("ruby-elf", Elf::VERSION) do |pkg|
  pkg.need_tar_bz2 = true
  pkg.package_dir = "pkg"
  pkg.package_files = IO.popen("git ls-files").lines.collect do |line|
    next if line == /^\.gitignore/
    line.strip
  end
  pkg.package_files << "ruby-elf-#{Elf::VERSION}.gemspec"
end

require 'rake/gempackagetask'
Rake::GemPackageTask.new(Spec) do |pkg|
end

# Local Variables:
# mode: ruby
# mode: flyspell-prog
# ispell-local-dictionary: "english"
# End:
