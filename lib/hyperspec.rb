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

      def responds_with
        Have.new(response)
      end

      private
      def do_request
        klass = eval("Net::HTTP::#{request_type.to_s.gsub(/^\w/) { |c| c.upcase }}")
        @do_request ||=
          request_response(klass, base_uri, headers)
      end

      def request_response(klass, uri, headers, body = '')
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
