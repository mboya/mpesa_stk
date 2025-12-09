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
  # Customer to Business API - register URLs and simulate C2B payments
  class C2B
    class << self
      def register_url(hash = {})
        new(hash).register
      end

      def simulate(amount, phone_number, hash = {})
        new(hash).simulate_payment(amount, phone_number)
      end
    end

    attr_reader :token, :short_code, :response_type, :confirmation_url, :validation_url, :command_id, :bill_ref_number

    def initialize(hash = {})
      @token = MpesaStk::AccessToken.call(hash['key'], hash['secret'])
      @short_code = hash['short_code'] || ENV.fetch('business_short_code', nil)
      @response_type = hash['response_type'] || 'Completed'
      @confirmation_url = hash['confirmation_url'] || ENV.fetch('confirmation_url', nil)
      @validation_url = hash['validation_url']
      @command_id = hash['command_id'] || 'CustomerPayBillOnline'
      @bill_ref_number = hash['bill_ref_number'] || ''
    end

    def register
      response = HTTParty.post(register_url_endpoint, headers: headers, body: register_body)

      raise StandardError, "Failed to register C2B URL: #{response.code} - #{response.body}" unless response.success?

      JSON.parse(response.body)
    end

    def simulate_payment(amount, phone_number)
      response = HTTParty.post(simulate_url_endpoint, headers: headers, body: simulate_body(amount, phone_number))

      raise StandardError, "Failed to simulate C2B payment: #{response.code} - #{response.body}" unless response.success?

      JSON.parse(response.body)
    end

    private

    def register_url_endpoint
      "#{ENV.fetch('base_url', nil)}#{ENV.fetch('c2b_register_url', nil)}"
    end

    def simulate_url_endpoint
      "#{ENV.fetch('base_url', nil)}#{ENV.fetch('c2b_simulate_url', nil)}"
    end

    def headers
      {
        'Authorization' => "Bearer #{token}",
        'Content-Type' => 'application/json'
      }
    end

    def register_body
      body_hash = {
        ShortCode: get_short_code,
        ResponseType: response_type,
        ConfirmationURL: get_confirmation_url
      }
      body_hash[:ValidationURL] = validation_url if validation_url
      body_hash.to_json
    end

    def simulate_body(amount, phone_number)
      {
        ShortCode: get_short_code,
        CommandID: command_id,
        Amount: amount.to_s,
        Msisdn: phone_number,
        BillRefNumber: bill_ref_number
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

    def get_confirmation_url
      if confirmation_url.nil? || confirmation_url.eql?('')
        raise ArgumentError, 'Confirmation URL is not defined' if ENV['confirmation_url'].nil? || ENV['confirmation_url'].eql?('')

        ENV.fetch('confirmation_url', nil)

      else
        confirmation_url
      end
    end
  end
end
