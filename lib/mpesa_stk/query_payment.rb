require "mpesa_stk/access_token"

module MpesaStk
  class QueryPayment
    class << self
      def call(checkout_request_id)
        new(checkout_request_id).query_payment
      end
    end

    attr_reader :token, :checkout_request_id

    def initialize checkout_request_id
      @token = MpesaStk::AccessToken.call
      @checkout_request_id = checkout_request_id
    end

    def query_payment
      response = HTTParty.post(url, headers: headers, body: body)
      JSON.parse(response.body)
    end

    private
      def url
        "#{ENV['base_url']}#{ENV['query_payment_url']}"
      end

      def headers
        {
          "Authorization" => "Bearer #{token}",
          "Content-Type" => "application/json"
        }
      end

      def body
        {
          BusinessShortCode: "#{ENV['business_short_code']}",
          Password: generate_password,
          Timestamp: "#{timestamp}",
          CheckoutRequestID: "#{checkout_request_id}"
        }.to_json
      end

      def timestamp
        DateTime.now.strftime("%Y%m%d%H%M%S").to_i
      end

      def generate_password
        key = "#{ENV['business_short_code']}#{ENV['business_passkey']}#{timestamp}"
        Base64.encode64(key).split("\n").join
      end
  end
end
