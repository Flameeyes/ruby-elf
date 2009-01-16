task :default => [:test]

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = ['tests/ts_rubyelf.rb']
end

begin
  require 'rcov/rcovtask'
  
  Rcov::RcovTask.new do |t|
    t.test_files = ['tests/ts_rubyelf.rb']
  end
rescue LoadError
  $stderr.puts "Unable to find rcov, coverage won't be available"
end

# Local Variables:
# mode: ruby
# mode: flyspell-prog
# ispell-local-dictionary: "english"
# End:
