require "mpesa_stk/access_token"

module MpesaStk
  class PushPayment
    class << self
      def call(amount, phone_number)
        new(amount, phone_number).push_payment
      end
    end

    attr_reader :token, :amount, :phone_number

    def initialize amount, phone_number
      @token = MpesaStk::AccessToken.call
      @amount = amount
      @phone_number = phone_number
    end

    def push_payment
      response = HTTParty.post(url, headers: headers, body: body)
      JSON.parse(response.body)
    end

    private
      def url
        "#{ENV['base_url']}#{ENV['process_request_url']}"
      end

      def headers
        headers = {
          "Authorization" => "Bearer #{token}",
          "Content-Type" => "application/json"
        }
      end

      def body
        {
          BusinessShortCode: "#{ENV['business_short_code']}",
          Password: generate_password,
          Timestamp: "#{timestamp}",
          TransactionType: "CustomerPayBillOnline",
          Amount: "#{amount}",
          PartyA: "#{phone_number}",
          PartyB: "#{ENV['business_short_code']}",
          PhoneNumber: "#{phone_number}",
          CallBackURL: "#{ENV['callback_url']}",
          AccountReference: generate_bill_reference_number(5),
          TransactionDesc: generate_bill_reference_number(5)
        }.to_json
      end

      def generate_bill_reference_number(number)
        charset = Array('A'..'Z') + Array('a'..'z')
        Array.new(number) { charset.sample }.join
      end

      def timestamp
        DateTime.now.strftime("%Y%m%d%H%M%S").to_i
      end

      # shortcode
      # passkey
      # timestamp
      def generate_password
        key = "#{ENV['business_short_code']}#{ENV['business_passkey']}#{timestamp}"
        Base64.encode64(key).split("\n").join
      end

  end
end