require 'uri'

gem 'minitest' # Ensure gem is used over built in.
require 'minitest/spec'
require 'minitest/autorun'

require 'vcr'
require './spec/support/vcr'

$:.push File.expand_path("../../lib", __FILE__)
require 'hyperspec'

VCR.config do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.stub_with :fakeweb
end

describe HyperSpec do
  it "should be of version 0.0.0" do
    HyperSpec::VERSION.must_equal "0.0.0"
  end

  describe "MiniTest::Spec extensions" do
    describe "service" do
      # `service` is added to `Kernel`, but conveniently enough
      # returns a sub class of MiniTest::Spec which can be tested.
      subject do
        service("http://lolc.at") {}.
          new("Required name.")
      end

      it { subject.must_be_kind_of MiniTest::Spec }
      it { subject.base_uri.must_equal URI.parse("http://lolc.at/") }
      it { subject.headers.must_equal({}) }
    end

    describe "resource" do
      # `resource` is added to `Kernel`, but conveniently enough
      # returns a sub class of MiniTest::Spec which can be tested,
      # though this time we must tap into the `service` and bind it.
      subject do
        this = nil

        service("http://lolc.at") do
          this = resource("/lolz") {}
        end

        this.new("This is the name.")
      end

      it { subject.must_be_kind_of MiniTest::Spec }
      it { subject.base_uri.must_equal URI.parse("http://lolc.at/lolz") }
      it { subject.headers.must_equal({}) }
    end

    describe "with_headers" do
      # `resource` is added to `Kernel`, but conveniently enough
      # returns a sub class of MiniTest::Spec which can be tested,
      # though this time we must tap into the `service` and bind it.
      subject do
        this = nil

        service("http://localhost") do
          this =
            resource("/lolz") do
              with_headers({ 'X-Camel-Size' => 'LARGE' })
            end
        end

        this.new("This is the name.")
      end

      it { subject.must_be_kind_of MiniTest::Spec }
      it { subject.base_uri.must_equal URI.parse("http://localhost/lolz") }
      it { subject.headers.must_equal({ 'X-Camel-Size' => 'LARGE' }) }
    end

    %w[ get head post put delete ].map(&:to_sym).each do |http_method|
      describe "HTTP method selection" do
        subject do
          this = nil

          service("http://localhost") do
            resource("/") do
              this = send(http_method) {}
            end
          end

          this.new("This is the name.")
        end

        it { subject.request_type.must_equal http_method }

        describe "mock requests" do
          use_vcr_cassette('localhost')

          it do
            subject.response.status_code.must_equal 200
          end
        end
      end
    end
  end
end
