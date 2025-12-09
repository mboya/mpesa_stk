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
  # Initiates STK Push payment for multiple applications with custom credentials
  class Push
    class << self
      def pay_bill(amount, phone_number, hash = {})
        new(amount, phone_number, 'CustomerPayBillOnline', nil, hash['business_short_code'], hash['callback_url'],
            hash['business_passkey'], hash['key'], hash['secret']).push_payment
      end

      def buy_goods(amount, phone_number, hash = {})
        new(amount, phone_number, 'CustomerBuyGoodsOnline', hash['till_number'], hash['business_short_code'],
            hash['callback_url'], hash['business_passkey'], hash['key'], hash['secret']).push_payment
      end
    end

    attr_reader :token, :amount, :phone_number, :till_number, :business_short_code, :callback_url, :business_passkey,
                :transaction_type

    def initialize(amount, phone_number, transaction_type, till_number = nil, business_short_code = nil,
                   callback_url = nil, business_passkey = nil, key = nil, secret = nil)
      @token = MpesaStk::AccessToken.call(key, secret)
      @transaction_type = transaction_type
      @till_number = till_number
      @business_short_code = business_short_code
      @callback_url = callback_url
      @business_passkey = business_passkey
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
        BusinessShortCode: get_business_short_code,
        Password: generate_password,
        Timestamp: timestamp.to_s,
        TransactionType: transaction_type,
        Amount: amount.to_s,
        PartyA: phone_number.to_s,
        PartyB: get_till_number,
        PhoneNumber: phone_number.to_s,
        CallBackURL: get_callback_url,
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

    def get_callback_url
      if callback_url.nil? || callback_url.eql?('')
        raise ArgumentError, 'Callback URL is not defined' if ENV['callback_url'].nil? || ENV['callback_url'].eql?('')

        ENV.fetch('callback_url', nil)

      else
        callback_url
      end
    end

    def get_till_number
      if transaction_type.eql?('CustomerPayBillOnline')
        get_business_short_code
      elsif till_number.nil?
        raise ArgumentError, 'Till number is not defined' if ENV['till_number'].nil? || ENV['till_number'].eql?('')

        ENV.fetch('till_number', nil)

      else
        till_number
      end
    end
  end
end
