# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{aggregate}
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joseph Ruscio"]
  s.date = %q{2009-08-11}
  s.description = %q{Aggregate is a Ruby library accumulating aggregate statistics (including histograms) in an object oriented manner.}
  s.email = %q{jruscio@gmail.com}
  s.homepage = %q{http://github.com/josephruscio/aggregate}
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.files = ["README", "LICENSE", "lib/aggregate.rb", "test/ts_aggregate.rb"]
  s.test_file = "test/ts_aggregate.rb"
  s.has_rdoc = true
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  #s.rubyforge_project = %q{aggregate}
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{Aggregate is a Ruby library accumulating aggregate statistics (including histograms) in an object oriented manner.}
end
