gem 'minitest' # Ensure gem is used over built in.
require 'minitest/spec'
require 'minitest/autorun'

$:.push File.expand_path("../../lib", __FILE__)
require 'hyperspec'

describe HyperSpec do
  it "should be of version 0.0.0" do
    HyperSpec::VERSION.must_equal "0.0.0"
  end
end
