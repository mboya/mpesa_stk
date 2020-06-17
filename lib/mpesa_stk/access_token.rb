require 'base64'
require 'redis'

module MpesaStk
  class AccessToken
    class << self
      def call(key = nil, secret = nil)
        new(key, secret).access_token
      end
    end

    def initialize(key = nil, secret = nil)
      @key = key.nil? ? ENV['key'] : key
      @secret = secret.nil? ? ENV['secret'] : secret
      @redis = Redis.new

      load_from_redis
    end

    def is_valid?
      has_token? && !token_expired?
    end

    def token_expired?
      expire_time = @timestamp.to_i + @expires_in.to_i
      return expire_time < Time.now.to_i + 58
    end

    def has_token?
      return !@token.nil?
    end

    def refresh
      get_new_access_token
      load_from_redis
    end

    def load_from_redis
      data = @redis.get(@key)
      if (data.nil? || data.empty?)
        @token = nil
        @timestamp = nil
        @expires_in = nil
      else
        parsed = JSON.parse(data)
        @token = parsed['access_token']
        @timestamp = parsed['time_stamp']
        @expires_in = parsed['expires_in']
      end
    end

    def access_token
      if is_valid?
        return @token
      else
        refresh
        return @token
      end
    end

    def get_new_access_token
      response = HTTParty.get(url, headers: headers)

      hash = JSON.parse(response.body).merge(Hash['time_stamp', Time.now.to_i])
      @redis.set @key, hash.to_json
    end

    private

    def url
      "#{ENV['base_url']}#{ENV['token_generator_url']}"
    end

    def headers
      encode = encode_credentials @key, @secret
      {
        "Authorization" => "Basic #{encode}"
      }
    end

    def encode_credentials key, secret
      credentials = "#{key}:#{secret}"
      Base64.encode64(credentials).split("\n").join
    end
  end
end
