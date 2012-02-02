# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "hyperspec/version"

Gem::Specification.new do |s|
  s.name        = "hyperspec"
  s.version     = HyperSpec::VERSION
  s.authors     = [ "Hannes Tydén" ]
  s.email       = [ "hannes@soundcloud.com" ]
  s.homepage    = "http://github.com/hannestyden/hyperspec"
  s.summary     = "Full stack HTTP API testing DSL."
  s.description = <<-DESCRIPTION
    By extending minitest/spec HyperSpec provides a Ruby DSL for testing HTTP APIs from the "outside".
  DESCRIPTION

  # Required for validation.
  s.rubyforge_project = "hyperspec"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = [ "lib" ]

  dependencies =
    [
      [ "minitest", "~> 2.11" ],
    ]

  developement_dependencies =
    [
      [ "vcr",     "~> 1.6" ],
      [ "webmock" ],
    ]

  runtime_dependencies      = []

  (dependencies + developement_dependencies).each do |dependency|
    s.add_development_dependency *dependency
  end

  (dependencies + developement_dependencies).each do |dependency|
    s.add_runtime_dependency *dependency
  end
end
