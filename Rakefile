# -*- coding: utf-8 -*-

# Ensure that the lib/ directory is used before the one installed in
# the system to get the right version, then require the library
# itself.
$:.insert(0, File.expand_path("../lib", __FILE__))
require 'elf'

ManpagesList = FileList["manpages/*.1.xml"].collect { |file|
  file.sub(/\.1\.xml$/, ".1")
}

desc "Build the man pages for the installed tools"
task :manpages => ManpagesList

desc "Remove manpages products"
task :clobber_manpages do
  FileList["manpages/*.1"].each do |file|
    File.unlink(file)
  end
end

begin
  def git_tagged?
    unless File.exists?(".git")
      raise Exception.new("Can't execute this task outside of Ruby-Elf git repository")
    end

    IO.popen("git tag -l #{Elf::VERSION}").read == "#{Elf::VERSION}\n"
  end

  def git_dirty?
    unless File.exists?(".git")
      raise Exception.new("Can't execute this task outside of Ruby-Elf git repository")
    end

    IO.popen("git status --porcelain --untracked-files=no").read != ""
  end

  desc "Tag and publish the release"
  task :package => ManpagesList do
    if git_tagged?
      $stderr.puts "The current release is already tagged; did you forget to bump the version?"
      exit 1
    end

    if git_dirty?
      $stderr.puts "The git repository contains modifications that are not committed."
      exit 1
    end

    sh "gem", "build", "ruby-elf.gemspec"
    sh "git", "tag", "-m", "Release #{Elf::VERSION}", "#{Elf::VERSION}"
    sh "gem", "push", "ruby-elf-#{Elf::VERSION}.gem"
  end
rescue Exception => e
  # This can happen for instance if you're not running from within a
  # git checkout. In that case we ignore the whole file.
  raise unless e.message == "Can't execute this task outside of Ruby-Elf git repository"
end

XSL_NS_ROOT="http://docbook.sourceforge.net/release/xsl-ns/current"

rule '.1' => [ '.1.xml' ] + FileList["manpages/*.xmli"] do |t|
  sh "xsltproc", "--stringparam", "man.copyright.section.enabled", "0", \
  "--xinclude", "-o", t.name, "#{XSL_NS_ROOT}/manpages/docbook.xsl", \
  t.source
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs = ["lib", "test"]
end

begin
  require 'rcov/rcovtask'
  
  Rcov::RcovTask.new do |t|
    t.libs = ["lib", "test"]
  end
rescue LoadError
  $stderr.puts "Unable to find rcov, coverage won't be available"
end

task :default => [:test]

# Local Variables:
# mode: ruby
# mode: flyspell-prog
# ispell-local-dictionary: "english"
# End:
