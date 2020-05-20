# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aggregate/version'

Gem::Specification.new do |s|
  s.name = %q{aggregate}
  s.version = Aggregate::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joseph Ruscio"]
  s.description = %q{Aggregate is a Ruby class for accumulating aggregate statistics and includes histogram support. For a detailed README see: http://github.com/josephruscio/aggregate}
  s.email = %q{joe@ruscio.org}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.textile"
  ]
  s.files = Dir["{lib}/**/*.*", "LICENSE", "README.textile"]
  s.homepage = %q{http://github.com/josephruscio/aggregate}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.summary = %q{Aggregate is a Ruby class for accumulating aggregate statistics and includes histogram support}
  s.test_files = [
    "test/ts_aggregate.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
