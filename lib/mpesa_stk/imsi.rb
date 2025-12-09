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
  # IMSI/SWAP Operations - query IMSI and SIM swap information for fraud prevention
  class IMSI
    class << self
      def check_ati(customer_number, hash = {}, version: 'v1')
        new(hash).check_ati(customer_number, version)
      end
    end

    attr_reader :token

    def initialize(hash = {})
      @token = MpesaStk::AccessToken.call(hash['key'], hash['secret'])
    end

    def check_ati(customer_number, version = 'v1')
      endpoint = version == 'v2' ? '/imsi/v2/checkATI' : '/imsi/v1/checkATI'
      response = HTTParty.post(url(endpoint), headers: headers, body: body(customer_number))

      raise StandardError, "Failed to check ATI: #{response.code} - #{response.body}" unless response.success?

      JSON.parse(response.body)
    end

    private

    def url(endpoint)
      "#{ENV.fetch('base_url', nil)}#{endpoint}"
    end

    def headers
      {
        'Authorization' => "Bearer #{token}",
        'Content-Type' => 'application/json'
      }
    end

    def body(customer_number)
      {
        customerNumber: customer_number
      }.to_json
    end
  end
end
