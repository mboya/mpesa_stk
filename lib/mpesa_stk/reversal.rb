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
  # Reverse M-Pesa transactions (full or partial)
  class Reversal
    class << self
      def reverse(transaction_id, amount, hash = {})
        new(transaction_id, amount, hash).reverse_transaction
      end
    end

    attr_reader :token, :transaction_id, :amount, :initiator, :security_credential, :receiver_party,
                :receiver_identifier_type, :result_url, :queue_timeout_url

    def initialize(transaction_id, amount, hash = {})
      @token = MpesaStk::AccessToken.call(hash['key'], hash['secret'])
      @transaction_id = transaction_id
      @amount = amount
      @initiator = hash['initiator'] || ENV.fetch('initiator', nil)
      @security_credential = hash['security_credential'] || ENV.fetch('security_credential', nil)
      @receiver_party = hash['receiver_party'] || ENV.fetch('business_short_code', nil)
      @receiver_identifier_type = hash['receiver_identifier_type'] || '4'
      @result_url = hash['result_url'] || ENV.fetch('result_url', nil)
      @queue_timeout_url = hash['queue_timeout_url'] || ENV.fetch('queue_timeout_url', nil)
    end

    def reverse_transaction
      response = HTTParty.post(url, headers: headers, body: body)

      raise StandardError, "Failed to reverse transaction: #{response.code} - #{response.body}" unless response.success?

      JSON.parse(response.body)
    end

    private

    def url
      "#{ENV.fetch('base_url', nil)}#{ENV.fetch('reversal_url', nil)}"
    end

    def headers
      {
        'Authorization' => "Bearer #{token}",
        'Content-Type' => 'application/json'
      }
    end

    def body
      {
        Initiator: get_initiator,
        SecurityCredential: get_security_credential,
        CommandID: 'TransactionReversal',
        TransactionID: transaction_id,
        Amount: amount.to_s,
        ReceiverParty: get_receiver_party,
        RecieverIdentifierType: receiver_identifier_type,
        ResultURL: get_result_url,
        QueueTimeOutURL: get_queue_timeout_url
      }.to_json
    end

    def get_initiator
      if initiator.nil? || initiator.eql?('')
        raise ArgumentError, 'Initiator is not defined' if ENV['initiator'].nil? || ENV['initiator'].eql?('')

        ENV.fetch('initiator', nil)

      else
        initiator
      end
    end

    def get_security_credential
      if security_credential.nil? || security_credential.eql?('')
        if ENV['security_credential'].nil? || ENV['security_credential'].eql?('')
          raise ArgumentError, 'Security Credential is not defined'
        end

        ENV.fetch('security_credential', nil)

      else
        security_credential
      end
    end

    def get_receiver_party
      if receiver_party.nil? || receiver_party.eql?('')
        if ENV['business_short_code'].nil? || ENV['business_short_code'].eql?('')
          raise ArgumentError, 'Receiver Party (Business Short Code) is not defined'
        end

        ENV.fetch('business_short_code', nil)

      else
        receiver_party
      end
    end

    def get_result_url
      if result_url.nil? || result_url.eql?('')
        raise ArgumentError, 'Result URL is not defined' if ENV['result_url'].nil? || ENV['result_url'].eql?('')

        ENV.fetch('result_url', nil)

      else
        result_url
      end
    end

    def get_queue_timeout_url
      if queue_timeout_url.nil? || queue_timeout_url.eql?('')
        if ENV['queue_timeout_url'].nil? || ENV['queue_timeout_url'].eql?('')
          raise ArgumentError, 'Queue Timeout URL is not defined'
        end

        ENV.fetch('queue_timeout_url', nil)

      else
        queue_timeout_url
      end
    end
  end
end
