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
      describe(desc, additional_desc, &block).tap do |cls|
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
        Have.new(response)
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

  Response = Struct.new(:status_code, :headers, :body) do
    STATI = {
      # 2xx
      200 => :ok,
      201 => :created,

      # 4xx
      401 => :unauthorized,
      411 => :length_required,

      # WebDav extensions
      422 => :unprocessable_entity,
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
end

::Object.send(:include, HyperSpec::ObjectExtensions)
::MiniTest::Spec.send(:include, HyperSpec::MiniTest::SpecExtensions)
