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

require 'date'
require 'mpesa_stk/access_token'

module MpesaStk
  # Query STK Push transaction status using CheckoutRequestID
  class StkPushQuery
    class << self
      def query(checkout_request_id, hash = {})
        new(checkout_request_id, hash).query_status
      end
    end

    attr_reader :token, :checkout_request_id, :business_short_code, :business_passkey

    def initialize(checkout_request_id, hash = {})
      @token = MpesaStk::AccessToken.call(hash['key'], hash['secret'])
      @checkout_request_id = checkout_request_id
      @business_short_code = hash['business_short_code'] || ENV.fetch('business_short_code', nil)
      @business_passkey = hash['business_passkey'] || ENV.fetch('business_passkey', nil)
    end

    def query_status
      response = HTTParty.post(url, headers: headers, body: body)

      raise StandardError, "Failed to query STK push status: #{response.code} - #{response.body}" unless response.success?

      JSON.parse(response.body)
    end

    private

    def url
      "#{ENV.fetch('base_url', nil)}#{ENV.fetch('stk_push_query_url', nil)}"
    end

    def headers
      {
        'Authorization' => "Bearer #{token}",
        'Content-Type' => 'application/json'
      }
    end

    def body
      {
        BusinessShortCode: get_business_short_code,
        Password: generate_password,
        Timestamp: timestamp.to_s,
        CheckoutRequestID: checkout_request_id
      }.to_json
    end

    def timestamp
      DateTime.now.strftime('%Y%m%d%H%M%S').to_i
    end

    def generate_password
      key = "#{get_business_short_code}#{get_business_passkey}#{timestamp}"
      Base64.encode64(key).split("\n").join
    end

    def get_business_short_code
      if business_short_code.nil? || business_short_code.eql?('')
        if ENV['business_short_code'].nil? || ENV['business_short_code'].eql?('')
          raise ArgumentError, 'Business Short Code is not defined'
        end

        ENV.fetch('business_short_code', nil)

      else
        business_short_code
      end
    end

    def get_business_passkey
      if business_passkey.nil? || business_passkey.eql?('')
        raise ArgumentError, 'Business Passkey is not defined' if ENV['business_passkey'].nil? || ENV['business_passkey'].eql?('')

        ENV.fetch('business_passkey', nil)

      else
        business_passkey
      end
    end
  end
end
