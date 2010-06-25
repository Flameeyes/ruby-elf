task :default => [:test]

desc "Build the Ruby demanglers based on the Ragel code"
task :demanglers do
  sh 'make demanglers-build'
end

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
