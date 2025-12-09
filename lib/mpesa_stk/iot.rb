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
require 'securerandom'

module MpesaStk
  # IoT SIM Management & Messaging - manage SIM cards and send/receive messages for IoT devices
  class IoT
    class << self
      def sims(hash = {})
        new(hash)
      end

      def messaging(hash = {})
        new(hash)
      end
    end

    attr_reader :token, :api_key, :vpn_group, :username

    def initialize(hash = {})
      @token = MpesaStk::AccessToken.call(hash['key'], hash['secret'])
      @api_key = hash['api_key'] || ENV['iot_api_key'] || 'Yl4S3KEcr173mbeUdYdjf147IuG3rJ824ArMkP6Z'
      @vpn_group = hash['vpn_group'] || ENV['vpn_group'] || ''
      @username = hash['username'] || ENV['username'] || ''
    end

    # SIM Operations
    def get_all_sims(start_at_index: 0, page_size: 10)
      post_request('/allsims', {
                     vpnGroup: [vpn_group],
                     startAtIndex: start_at_index.to_s,
                     pageSize: page_size.to_s,
                     username: username
                   })
    end

    def query_lifecycle_status(msisdn)
      post_request('/queryLifeCycleStatus', {
                     msisdn: msisdn,
                     vpnGroup: vpn_group,
                     username: username
                   })
    end

    def query_customer_info(msisdn)
      post_request('/querycustomerinfo', {
                     msisdn: msisdn,
                     vpnGroup: vpn_group,
                     username: username
                   })
    end

    def sim_activation(msisdn)
      post_request('/simactivation', {
                     msisdn: msisdn,
                     vpnGroup: vpn_group,
                     username: username
                   })
    end

    def get_activation_trends(start_date:, stop_date:)
      post_request('/getactivationtrends', {
                     vpnGroup: vpn_group,
                     startDate: start_date,
                     stopDate: stop_date,
                     username: username
                   })
    end

    def rename_asset(msisdn, asset_name)
      post_request('/renameasset', {
                     msisdn: msisdn,
                     vpnGroup: vpn_group,
                     username: username,
                     assetName: asset_name
                   })
    end

    def get_location_info(msisdn)
      post_request('/getlocationinfo', {
                     msisdn: msisdn,
                     vpnGroup: vpn_group,
                     username: username
                   })
    end

    def suspend_unsuspend_sub(msisdn, product, operation)
      post_request('/suspend_unsuspend_sub', {
                     msisdn: msisdn,
                     username: username,
                     vpnGroup: vpn_group,
                     product: product,
                     operation: operation
                   })
    end

    # Messaging Operations
    def get_all_messages(page_no: 1, page_size: 10)
      get_request("/getallmessages?pageNo=#{page_no}&pageSize=#{page_size}", {
                    vpnGroup: vpn_group
                  })
    end

    def search_messages(search_value, page_no: 1, page_size: 5)
      get_request("/searchmessages?pageNo=#{page_no}&pageSize=#{page_size}", {
                    searchValue: search_value,
                    vpnGroup: vpn_group,
                    username: username
                  })
    end

    def filter_messages(start_date:, end_date:, status: '', page_no: 1, page_size: 10)
      get_request("/filtermessages?pageNo=#{page_no}&pageSize=#{page_size}", {
                    startDate: start_date,
                    endDate: end_date,
                    status: status,
                    vpnGroup: vpn_group,
                    username: username
                  })
    end

    def send_single_message(msisdn, message)
      post_request('/sendsinglemessage', {
                     msisdn: msisdn,
                     message: message,
                     vpnGroup: vpn_group,
                     username: username
                   })
    end

    def delete_message(message_id)
      post_request('/deletemessage', {
                     id: message_id,
                     vpnGroup: vpn_group,
                     username: username
                   })
    end

    def delete_message_thread(msisdn)
      post_request('/deleteMessageThread', {
                     msisdn: msisdn,
                     vpnGroup: vpn_group,
                     username: username
                   })
    end

    private

    def base_url
      "#{ENV.fetch('base_url', nil)}#{ENV.fetch('iot_base_url', nil)}"
    end

    def headers(msisdn: nil)
      headers_hash = {
        'Authorization' => "Bearer #{token}",
        'Content-Type' => 'application/json',
        'x-correlation-conversationid' => SecureRandom.uuid,
        'x-source-system' => 'web-portal',
        'x-api-key' => api_key,
        'X-App' => 'web-portal',
        'X-MessageID' => SecureRandom.uuid
      }
      headers_hash['X-MSISDN'] = msisdn if msisdn
      headers_hash
    end

    def post_request(endpoint, body)
      response = HTTParty.post("#{base_url}#{endpoint}", headers: headers(msisdn: body[:msisdn]), body: body.to_json)

      raise StandardError, "Failed IoT request: #{response.code} - #{response.body}" unless response.success?

      JSON.parse(response.body)
    end

    def get_request(endpoint, body)
      response = HTTParty.post("#{base_url}#{endpoint}", headers: headers, body: body.to_json)

      raise StandardError, "Failed IoT request: #{response.code} - #{response.body}" unless response.success?

      JSON.parse(response.body)
    end
  end
end
