require 'uri'
require 'net/http'

gem 'minitest' # Ensure gem is used over built in.
require 'minitest/spec'

require 'hyperspec/version'

module HyperSpec
  module ObjectExtensions
    private
    def service(desc, additional_desc = nil, &block)
      describe(desc, additional_desc, &block).tap do |cls|
        cls.class_eval do
          define_method(:base_uri)     { URI.parse(desc) }
          define_method(:headers)      { {} }
          define_method(:request_body) { "" }
        end
      end
    end

    def resource(path, additional_desc = nil, &block)
      describe(path, additional_desc, &block).tap do |cls|
        cls.class_eval do
          define_method(:base_uri) do
            super().tap do |s|
              s.path = [ s.path, path ].reject(&:empty?).join("/")
            end
          end
        end
      end
    end

    def with_headers(hash, additional_desc = nil, &block)
      describe("with headers", additional_desc, &block).tap do |cls|
        cls.class_eval do
          define_method(:headers) { super().merge(hash) }
        end
      end
    end

    def with_query(string, additional_desc = nil, &block)
      describe("with query", additional_desc, &block).tap do |cls|
        cls.class_eval do
          define_method(:base_uri) do
            super().tap do |s|
              s.query = [ s.query.to_s, string ].reject(&:empty?).join("&")
            end
          end
        end
      end
    end

    def with_request_body(string, additional_desc = nil, &block)
      describe("with request body", additional_desc, &block).tap do |cls|
        cls.class_eval do
          define_method(:request_body) { string }
        end
      end
    end

    # HTTP method selection
    #
    # Hard coded method definitions is required for 1.8.7 compatibility.
    def get(additional_desc = nil, &block)
      _request('get', Net::HTTP::Get, additional_desc, &block)
    end

    def head(additional_desc = nil, &block)
      _request('head', Net::HTTP::Head, additional_desc, &block)
    end

    def post(additional_desc = nil, &block)
      _request('post', Net::HTTP::Post, additional_desc, &block)
    end

    def put(additional_desc = nil, &block)
      _request('put', Net::HTTP::Put, additional_desc, &block)
    end

    def delete(additional_desc = nil, &block)
      _request('delete', Net::HTTP::Delete, additional_desc, &block)
    end

    private
    def _request(http_method, request_class, additional_desc, &block)
      describe(http_method.upcase, additional_desc, &block).tap do |cls|
        cls.class_eval do
          define_method(:request_class) { request_class }
        end
      end
    end
  end

  module MiniTest
    module SpecExtensions
      def response
        do_request
      end

      def responds_with
        RespondsWith.new(response)
      end

      private
      def do_request
        @do_request ||=
          request_response(request_class, base_uri, headers, request_body)
      end

      def request_response(klass, uri, headers, body = '')
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = URI::HTTPS === uri

        # NO DON'T DO IT!
        # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        # YOU DIDN'T DO IT, DID YOU?

        resp =
          http.start do
            request_uri = [ uri.path, uri.query ].join("?")
            req = klass.new(request_uri)
            headers.inject(req) { |m, (k, v)| m[k] = v; m }
            req.body = body if body
            req.basic_auth(uri.user, uri.password) if uri.userinfo
            if headers['Content-Type']
              req.content_type = headers['Content-Type']
            end
            http.request(req)
          end

        Response.from_net_http_response(resp)
      end
    end
  end

  class UnkownStatusCodeError < StandardError; end

  Response = Struct.new(:status_code, :headers, :body) do
    STATI = {
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
    }

    def self.from_net_http_response(http)
      status_code = http.code.to_i
      body        = http.body

      headers =
        CaseInsensitiveHash.from_hash(http.to_hash)

      new(status_code, headers, body)
    end

    def content_type
      headers['Content-Type'].split(';').first
    end

    def content_charset
      (md = headers['Content-Type'].match(/;charset=(.*)/)) && md[1]
    end

    def status
      STATI[status_code]
    end
  end

  class CaseInsensitiveHash < Hash
    def self.from_hash(hash)
      hash.inject(new) do |m, (k, v)|
        m[k] = v.first
        m
      end
    end

    def []=(key, value)
      super(key.downcase, value)
    end

    def [](key)
      super(key.downcase)
    end
  end

  Have = Struct.new(:proxy) do
    def method_missing(method_name, *arguments, &block)
      proxy.send(method_name).must_equal(*arguments)
    end
  end

  class RespondsWith < Have
    def status(status_code_symbol)
      if STATI.has_value?(status_code_symbol)
        proxy.status.must_equal(status_code_symbol)
      else
        raise UnkownStatusCodeError,
          "Status code #{status_code_symbol.inspect} is unkown."
      end
    end
  end
end

::Object.send(:include, HyperSpec::ObjectExtensions)
::MiniTest::Spec.send(:include, HyperSpec::MiniTest::SpecExtensions)
