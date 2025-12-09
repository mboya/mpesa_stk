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
  # M-Pesa Ratiba (Standing Orders) - create recurring payments
  class Ratiba
    class << self
      def create_standing_order(hash = {})
        new(hash).create
      end
    end

    attr_reader :token, :standing_order_name, :business_short_code, :transaction_type, :amount, :party_a,
                :receiver_party_identifier_type, :callback_url, :account_reference, :transaction_desc,
                :frequency, :start_date, :end_date

    def initialize(hash = {})
      @token = MpesaStk::AccessToken.call(hash['key'], hash['secret'])
      @standing_order_name = hash['standing_order_name'] || 'Standing Order'
      @business_short_code = hash['business_short_code'] || ENV.fetch('business_short_code', nil)
      @transaction_type = hash['transaction_type'] || 'Standing Order Customer Pay Bill'
      @amount = hash['amount']
      @party_a = hash['party_a']
      @receiver_party_identifier_type = hash['receiver_party_identifier_type'] || '4'
      @callback_url = hash['callback_url'] || ENV.fetch('callback_url', nil)
      @account_reference = hash['account_reference'] || ''
      @transaction_desc = hash['transaction_desc'] || ''
      @frequency = hash['frequency'] || '3'
      @start_date = hash['start_date']
      @end_date = hash['end_date']
    end

    def create
      response = HTTParty.post(url, headers: headers, body: body)

      raise StandardError, "Failed to create standing order: #{response.code} - #{response.body}" unless response.success?

      JSON.parse(response.body)
    end

    private

    def url
      "#{ENV.fetch('base_url', nil)}#{ENV.fetch('ratiba_url', nil)}"
    end

    def headers
      {
        'Authorization' => "Bearer #{token}",
        'Content-Type' => 'application/json'
      }
    end

    def body
      {
        StandingOrderName: standing_order_name,
        BusinessShortCode: get_business_short_code,
        TransactionType: transaction_type,
        Amount: amount.to_s,
        PartyA: party_a,
        ReceiverPartyIdentifierType: receiver_party_identifier_type,
        CallBackURL: get_callback_url,
        AccountReference: account_reference,
        TransactionDesc: transaction_desc,
        Frequency: frequency,
        StartDate: start_date,
        EndDate: end_date
      }.to_json
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
