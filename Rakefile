require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "aggregate"
    gemspec.summary = "Aggregate is a Ruby class for accumulating aggregate statistics and includes histogram support"
    gemspec.description = "Aggregate is a Ruby class for accumulating aggregate statistics and includes histogram support. For a detailed README see: http://github.com/josephruscio/aggregate"
    gemspec.email = "joe@ruscio.org"
    gemspec.homepage = "http://github.com/josephruscio/aggregate"
    gemspec.authors = ["Joseph Ruscio"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/ts_*.rb']
  t.verbose = true
end

task :default => :test
