require 'uri'
require 'simple_oauth'
require 'http/parser'

module EventMachine
  module Twitter
    class Request

      def initialize(options = {})
        @options = DEFAULT_CONNECTION_OPTIONS.merge(options)
        @proxy = @options.delete(:proxy)
      end

      def request_data
        content = '123'

        data = []
        data << "#{@options[:method]} #{request_uri} HTTP/1.1"
        data << "Host: #{@options[:host]}"
        data << 'Accept: */*'
        data << "User-Agent: #{@options[:user_agent]}" if @options[:user_agent]
        data << "Content-type: #{@options[:content_type]}"
        data << "Content-length: #{content.length}"
        data << "Authorization: #{oauth_header}"
        data << "Proxy-Authorization: Basic #{proxy_header}" if proxy?

        if @options[:headers]
          @options[:headers].each do |name, value|
              data << "#{name}: #{value}"
          end
        end

        data << "\r\n"
      end

      def to_s
        request_data.join('\r\n')
      end

      def proxy?
        @proxy
      end

      def full_uri
        proxy? ? proxy_uri : "#{uri_base}#{request_uri}"
      end

      def proxy_uri
        "#{uri_base}:#{@options[:port]}#{@options[:path]}"
      end

      def request_uri
        proxy? ? proxy_uri : @options[:path]
      end

      # Scheme (https if ssl, http otherwise) and host part of URL
      def uri_base
        "https://#{@options[:host]}"
      end

      def proxy_header
        ["#{@proxy[:user]}:#{@proxy[:password]}"].pack('m').delete("\r\n")
      end

      # Normalized query hash of escaped string keys and escaped string values
      # nil values are skipped
      def params
        flat = {}
        @options[:params].each do |param, val|
          next if val.to_s.empty? || (val.respond_to?(:empty?) && val.empty?)
          val = val.join(",") if val.respond_to?(:join)
          flat[param.to_s] = val.to_s
        end
        flat
      end

      def query
        params.map do |param, value|
          [escape(param), escape(value)].join("=")
        end.sort.join("&")
      end

      def oauth_header
        oauth = {
          :consumer_key     => @options[:oauth][:consumer_key],
          :consumer_secret  => @options[:oauth][:consumer_secret],
          :token            => @options[:oauth][:token],
          :token_secret     => @options[:oauth][:token_secret]
        }

        puts @options.inspect
        puts full_uri
        puts params
        puts oauth

        SimpleOAuth::Header.new(@options[:method], full_uri, params, oauth)
      end
    end
  end
end