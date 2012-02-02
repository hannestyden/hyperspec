require 'uri'
require 'net/http'

require 'hyperspec/version'

module HyperSpec
  module ObjectExtensions
    private
    def service(desc, additional_desc = nil, &block)
      cls = describe(desc, additional_desc, &block)
      cls.send(:define_method, :base_uri) { URI.parse(desc) }
      cls.send(:define_method, :headers)  { {} }
      cls
    end

    def resource(desc, additional_desc = nil, &block)
      cls = describe(desc, additional_desc, &block)
      cls.send(:define_method, :base_uri) { super().merge(URI.parse(desc)) }
      cls
    end

    def with_headers(hash)
      cls = ::MiniTest::Spec.describe_stack.last
      cls.send(:define_method, :headers) { super().merge(hash) }
      cls
    end

    # HTTP method selection
    #
    def get(additional_desc = nil, &block)
      cls = describe('GET', additional_desc, &block)
      cls.instance_eval { |_| def request_type; :get; end }
      cls
    end

    def head(additional_desc = nil, &block)
      cls = describe('HEAD', additional_desc, &block)
      cls.instance_eval { |_| def request_type; :head; end }
      cls
    end
    def post(additional_desc = nil, &block)
      cls = describe('POST', additional_desc, &block)
      cls.instance_eval { |_| def request_type; :post; end }
      cls
    end
    def put(additional_desc = nil, &block)
      cls = describe('PUT', additional_desc, &block)
      cls.instance_eval { |_| def request_type; :put; end }
      cls
    end
    def delete(additional_desc = nil, &block)
      cls = describe('DELETE', additional_desc, &block)
      cls.instance_eval { |_| def request_type; :delete; end }
      cls
    end
  end

  module MiniTest
    module SpecExtensions
      def response
        do_request
      end

      def request_type
        self.class.request_type
      end

      private
      def do_request
        klass = eval("Net::HTTP::#{request_type.to_s.gsub(/^\w/) { |c| c.upcase }}")
        @do_request ||=
          Request.new(klass, base_uri, headers).response
      end
    end
  end

  Request = Struct.new(:klass, :uri, :headers, :body) do
    def response
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = URI::HTTPS === uri

      # NO DON'T DO IT!
      # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      # YOU DIDN'T DO IT, DID YOU?

      resp =
        http.start do
          req = klass.new(uri.path, headers)
          req.body = body if body
          http.request(req)
        end
      Response.from_net_http_response(resp)
    end
  end

  Response = Struct.new(:status_code, :headers, :body) do
    def self.from_net_http_response(http)
      status_code = http.code.to_i
      body        = http.body

      headers =
        http.to_hash.inject({}) do |m, (k, v)|
          k = k.gsub(/^\w|-\w/) { |c| c.upcase }
          m.update(k => v.first)
        end

      new(status_code, headers, body)
    end

    def content_type
      headers['Content-Type'].split(';').first
    end

    def content_charset
      headers['Content-Type'].split(';').last.gsub(/\s*charset=/, '')
    end

    def responds_with
      Have.new(self)
    end
  end
end

::Object.send(:include, HyperSpec::ObjectExtensions)
::MiniTest::Spec.send(:include, HyperSpec::MiniTest::SpecExtensions)
