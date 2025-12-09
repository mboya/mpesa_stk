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
  # Initiates STK Push payment for a single application using ENV variables
  class PushPayment
    class << self
      def call(amount, phone_number)
        new(amount, phone_number).push_payment
      end
    end

    attr_reader :token, :amount, :phone_number

    def initialize(amount, phone_number)
      @token = MpesaStk::AccessToken.call
      @amount = amount
      @phone_number = phone_number
    end

    def push_payment
      response = HTTParty.post(url, headers: headers, body: body)

      raise StandardError, "Failed to push payment: #{response.code} - #{response.body}" unless response.success?

      JSON.parse(response.body)
    end

    private

    def url
      "#{ENV.fetch('base_url', nil)}#{ENV.fetch('process_request_url', nil)}"
    end

    def headers
      {
        'Authorization' => "Bearer #{token}",
        'Content-Type' => 'application/json'
      }
    end

    def body
      {
        BusinessShortCode: ENV.fetch('business_short_code', nil).to_s,
        Password: generate_password,
        Timestamp: timestamp.to_s,
        TransactionType: 'CustomerPayBillOnline',
        Amount: amount.to_s,
        PartyA: phone_number.to_s,
        PartyB: ENV.fetch('business_short_code', nil).to_s,
        PhoneNumber: phone_number.to_s,
        CallBackURL: ENV.fetch('callback_url', nil).to_s,
        AccountReference: generate_bill_reference_number(5),
        TransactionDesc: generate_bill_reference_number(5)
      }.to_json
    end

    def generate_bill_reference_number(number)
      charset = Array('A'..'Z') + Array('a'..'z')
      Array.new(number) { charset.sample }.join
    end

    def timestamp
      DateTime.now.strftime('%Y%m%d%H%M%S').to_i
    end

    # shortcode
    # passkey
    # timestamp
    def generate_password
      key = "#{ENV.fetch('business_short_code', nil)}#{ENV.fetch('business_passkey', nil)}#{timestamp}"
      Base64.encode64(key).split("\n").join
    end
  end
end
