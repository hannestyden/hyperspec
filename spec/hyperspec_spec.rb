require 'uri'

# Ensure gem is used over 1.9.x built in.
gem 'minitest' if RUBY_VERSION =~ /1.9.\d/

require 'minitest/spec'
require 'minitest/autorun'

require 'vcr'
require './spec/support/vcr'
require './spec/support/meta_spec'

$:.push File.expand_path("../../lib", __FILE__)
require 'hyperspec'

VCR.config do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.stub_with :fakeweb
end

describe HyperSpec do
  include MetaSpec

  use_vcr_cassette('localhost')

  it "should be of version 0.0.5" do
    HyperSpec::VERSION.must_equal "0.0.5"
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
        the_spec do |bound|
          service("http://lolc.at") do
            bound.value = resource("/lolz") {}
          end
        end
      end

      it { subject.must_be_kind_of MiniTest::Spec }
      it { subject.base_uri.must_equal URI.parse("http://lolc.at/lolz") }
      it { subject.headers.must_equal({}) }
    end

    describe "nested resource" do
      # `resource` is added to `Kernel`, but conveniently enough
      # returns a sub class of MiniTest::Spec which can be tested,
      # though this time we must tap into the `service` and bind it.
      subject do
        the_spec do |bound|
          service("http://lolc.at") do
            resource("/lolz") do
              bound.value = resource("catz") {}
            end
          end
        end
      end

      it { subject.base_uri.must_equal URI.parse("http://lolc.at/lolz/catz") }
    end

    describe "with_headers" do
      subject do
        the_spec do |bound|
          service("http://localhost") do
            resource("/lolz") do
              bound.value = with_headers({ 'X-Camel-Size' => 'LARGE' }) {}
            end
          end
        end
      end

      it { subject.must_be_kind_of MiniTest::Spec }
      it { subject.base_uri.must_equal URI.parse("http://localhost/lolz") }
      it { subject.headers.must_equal({ 'X-Camel-Size' => 'LARGE' }) }
    end

    describe "with_query" do
      subject do
        the_spec do |bound|
          service("http://localhost") do
            resource("/lolz") do
              bound.value = with_query("q=monorail") {}
            end
          end
        end
      end

      it { subject.must_be_kind_of MiniTest::Spec }
      it { subject.base_uri.query.must_equal "q=monorail" }
    end

    describe "nested with_query" do
      subject do
        the_spec do |bound|
          service("http://localhost") do
            resource("/lolz") do
              with_query("q=monorail") do
                bound.value = with_query("q=lolz") {}
              end
            end
          end
        end
      end

      it 'should override previously set query values' do
        subject.base_uri.query.must_equal "q=lolz"
      end
    end

    describe "with_request_body" do
      subject do
        the_spec do |bound|
          service("http://localhost") do
            resource("/lolz") do
              bound.value = with_request_body("lol[title]=Roflcopter") {}
            end
          end
        end
      end

      it { subject.must_be_kind_of MiniTest::Spec }
      it { subject.request_body.must_equal "lol[title]=Roflcopter" }
    end

    {
      'get'    => Net::HTTP::Get,
      'head'   => Net::HTTP::Head,
      'post'   => Net::HTTP::Post,
      'put'    => Net::HTTP::Put,
      'delete' => Net::HTTP::Delete,
    }.each do |http_method, request_class|
      describe "HTTP method selection" do
        subject do
          the_spec do |bound|
            service("http://localhost") do
              resource("/") do
                bound.value = send(http_method) {}
              end
            end
          end
        end

        it { subject.request_class.must_equal request_class }
      end
    end

    describe "response" do
      subject do
        the_spec do |bound|
          service("http://localhost") do
            resource("/") do
              bound.value = get {}
            end
          end
        end.response
      end

      it { subject.status_code.must_be_kind_of Integer }
      it { subject.headers.must_be_kind_of Hash }
      it { subject.body.must_be_kind_of String }

      it { subject.content_type.must_be_kind_of String }
      it { subject.status.must_be_kind_of Symbol }

      describe "status" do
        {
          # RFC 2616 - HTTP 1.1
          ## Informational
          100 => :continue,
          101 => :switching_protocols,

          ## Successful 2xx
          200 => :ok,
          201 => :created,
          202 => :accepted,
          203 => :non_authoritative_information,
          204 => :no_content,
          205 => :reset_content,
          206 => :partial_content,

          ## Redirection 3xx
          300 => :multiple_choices,
          301 => :moved_permanently,
          302 => :found,
          303 => :see_other,
          304 => :not_modified,
          305 => :use_proxy,
        # 306 => :(Unused),
          307 => :temporary_redirect,

          ## Client Error 4xx,
          400 => :bad_request,
          401 => :unauthorized,
          402 => :payment_required,
          403 => :forbidden,
          404 => :not_found,
          405 => :method_not_allowed,
          406 => :not_acceptable,
          407 => :proxy_authentication_required,
          408 => :request_timeout,
          409 => :conflict,
          410 => :gone,
          411 => :length_required,
          412 => :precondition_failed,
          413 => :request_entity_too_large,
          414 => :request_uri_too_long,
          415 => :unsupported_media_type,
          416 => :requested_range_not_satisfiable,
          417 => :expectation_failed,

          ## Server Error 5xx
          500 => :internal_server_error,
          501 => :not_implemented,
          502 => :bad_gateway,
          503 => :service_unavailable,
          504 => :gateway_timeout,
          505 => :http_version_not_supported,

          # RFC 2324
          418 => :im_a_teapot,

          # RFC 4918 - WebDav
          207 => :multi_status,
          422 => :unprocessable_entity,
          423 => :locked,
          424 => :failed_dependency,
          507 => :insufficient_storage,

          # RFC 6585 - Additional HTTP Status Codes
          428 => :precondition_required,
          429 => :too_many_requests,
          431 => :request_header_fields_too_large,
          511 => :network_authentication_required,
        }.each do |code, status|
          it do
            subject.status_code = code
            subject.status.must_equal status
          end
        end
      end

      describe "content_charset" do
        it { subject.content_charset.must_be_kind_of String }
        it do
          subject.headers['Content-Type'] = "application/xml"
          subject.content_charset.must_be_nil
        end
      end

      describe "header access" do
        it "must be case insensitive" do
          subject.headers['Content-Length'].must_equal \
            subject.headers['content-length']
        end
      end
    end

    describe "responds_with" do
      subject do
        the_spec do |bound|
          service("http://localhost") do
            resource("/") do
              bound.value = get {}
            end
          end
        end.responds_with
      end

      it { subject.status_code 200 }
      it { subject.status :ok }

      it do
        lambda do
          subject.status :this_is_not_known
        end.must_raise HyperSpec::UnkownStatusCodeError
      end
    end

    describe "basic auth" do
      describe "with username" do
        subject do
          the_spec do |bound|
            service("http://username@localhost") do
              resource("/secret") do
                bound.value = get {}
              end
            end
          end.response
        end

        it { subject.status_code.must_equal 200 }
      end

      describe "with username and password" do
        subject do
          the_spec do |bound|
            service("http://username:password@localhost") do
              resource("/secret") do
                bound.value = get {}
              end
            end
          end.response
        end

        it { subject.status_code.must_equal 200 }
      end
    end
  end
end
