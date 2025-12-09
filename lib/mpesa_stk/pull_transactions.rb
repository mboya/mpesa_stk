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

require 'mpesa_stk/access_token'

module MpesaStk
  # Pull Transactions API - register URLs and query historical transaction data
  class PullTransactions
    class << self
      def register(hash = {})
        new(hash).register_url
      end

      def query(start_date, end_date, hash = {})
        new(hash).query_transactions(start_date, end_date)
      end
    end

    attr_reader :token, :short_code, :request_type, :nominated_number, :callback_url, :offset_value

    def initialize(hash = {})
      @token = MpesaStk::AccessToken.call(hash['key'], hash['secret'])
      @short_code = hash['short_code'] || ENV.fetch('business_short_code', nil)
      @request_type = hash['request_type'] || ''
      @nominated_number = hash['nominated_number'] || ''
      @callback_url = hash['callback_url'] || ENV.fetch('callback_url', nil)
      @offset_value = hash['offset_value'] || '0'
    end

    def register_url
      response = HTTParty.post(register_endpoint, headers: headers, body: register_body)

      unless response.success?
        raise StandardError, "Failed to register pull transactions URL: #{response.code} - #{response.body}"
      end

      JSON.parse(response.body)
    end

    def query_transactions(start_date, end_date)
      response = HTTParty.post(query_endpoint, headers: headers, body: query_body(start_date, end_date))

      raise StandardError, "Failed to query pull transactions: #{response.code} - #{response.body}" unless response.success?

      JSON.parse(response.body)
    end

    private

    def register_endpoint
      "#{ENV.fetch('base_url', nil)}#{ENV.fetch('pull_transactions_register_url', nil)}"
    end

    def query_endpoint
      "#{ENV.fetch('base_url', nil)}#{ENV.fetch('pull_transactions_query_url', nil)}"
    end

    def headers
      {
        'Authorization' => "Bearer #{token}",
        'Content-Type' => 'application/json'
      }
    end

    def register_body
      {
        ShortCode: get_short_code,
        RequestType: request_type,
        NominatedNumber: nominated_number,
        CallBackURL: get_callback_url
      }.to_json
    end

    def query_body(start_date, end_date)
      {
        ShortCode: get_short_code,
        StartDate: start_date,
        EndDate: end_date,
        OffSetValue: offset_value
      }.to_json
    end

    def get_short_code
      if short_code.nil? || short_code.eql?('')
        raise ArgumentError, 'Short Code is not defined' if ENV['business_short_code'].nil? || ENV['business_short_code'].eql?('')

        ENV.fetch('business_short_code', nil)

      else
        short_code
      end
    end

    def get_callback_url
      if callback_url.nil? || callback_url.eql?('')
        raise ArgumentError, 'Callback URL is not defined' if ENV['callback_url'].nil? || ENV['callback_url'].eql?('')

        ENV.fetch('callback_url', nil)

      else
        callback_url
      end
    end
  end
end
