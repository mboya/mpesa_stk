# frozen_string_literal: true

# Copyright (c) 2018 mboya
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'base64'
require 'json'
require 'redis'

module MpesaStk
  # Handles OAuth access token generation, caching, and refreshing for M-Pesa APIs
  class AccessToken
    class << self
      def call(key = nil, secret = nil)
        new(key, secret).access_token
      end
    end

    def initialize(key = nil, secret = nil)
      @key = key.nil? ? ENV.fetch('key', nil) : key
      @secret = secret.nil? ? ENV.fetch('secret', nil) : secret
      begin
        @redis = Redis.new
      rescue Redis::CannotConnectError, Redis::ConnectionError => e
        raise StandardError, "Failed to connect to Redis: #{e.message}"
      end

      load_from_redis
    end

    def valid?
      token? && !token_expired?
    end

    def token_expired?
      expire_time = @timestamp.to_i + @expires_in.to_i
      expire_time < Time.now.to_i + 58
    end

    def token?
      !@token.nil?
    end

    def refresh
      new_access_token
      load_from_redis
    end

    def load_from_redis
      data = @redis.get(@key)
      if data.nil? || data.empty?
        @token = nil
        @timestamp = nil
        @expires_in = nil
      else
        parsed = JSON.parse(data)
        @token = parsed['access_token']
        @timestamp = parsed['time_stamp']
        @expires_in = parsed['expires_in']
      end
    rescue Redis::BaseError => e
      raise StandardError, "Redis error: #{e.message}"
    end

    def access_token
      refresh unless valid?
      @token
    end

    def new_access_token
      response = HTTParty.get(url, headers: headers)

      raise StandardError, "Failed to get access token: #{response.code} - #{response.body}" unless response.success?

      hash = JSON.parse(response.body).merge({ 'time_stamp' => Time.now.to_i })
      @redis.set @key, hash.to_json
    rescue Redis::BaseError => e
      raise StandardError, "Redis error while saving token: #{e.message}"
    end

    private

    def url
      "#{ENV.fetch('base_url', nil)}#{ENV.fetch('token_generator_url', nil)}"
    end

    def headers
      encode = encode_credentials @key, @secret
      {
        'Authorization' => "Basic #{encode}"
      }
    end

    def encode_credentials(key, secret)
      credentials = "#{key}:#{secret}"
      Base64.encode64(credentials).split("\n").join
    end
  end
end
