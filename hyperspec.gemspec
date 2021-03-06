# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'hyperspec/version'

Gem::Specification.new do |s|
  s.name     = 'hyperspec'
  s.version  = HyperSpec::VERSION
  s.authors  = [ 'Hannes Tydén' ]
  s.email    = [ 'hannes@tyden.name' ]
  s.homepage = 'http://github.com/hannestyden/hyperspec'
  s.summary  = 'Full stack HTTP API testing DSL.'

  s.description = <<-DESCRIPTION
    By extending minitest/spec HyperSpec provides a Ruby DSL for testing
    HTTP APIs from the "outside".
  DESCRIPTION

  # Required for validation.
  s.rubyforge_project = 'hyperspec'

  s.files      = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.executables = `git ls-files -- bin/*`.
    split("\n").map { |f| File.basename(f) }

  s.require_paths = [ 'lib' ]

  s.add_dependency('minitest', '~> 2.11')

  s.add_development_dependency('vcr', '~> 1.6')
  s.add_development_dependency('fakeweb')
end
