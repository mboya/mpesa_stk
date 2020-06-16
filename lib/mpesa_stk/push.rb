require "mpesa_stk/access_token"

module MpesaStk
  class Push
    class << self
      def pay_bill(amount, phone_number, hash = {})
        new(amount, phone_number, "CustomerPayBillOnline", nil, hash["business_short_code"], hash["callback_url"], hash["business_passkey"], hash["key"], hash["secret"]).push_payment
      end

      def buy_goods(amount, phone_number, hash = {})
        new(amount, phone_number, "CustomerBuyGoodsOnline", hash["till_number"], hash["business_short_code"], hash["callback_url"], hash["business_passkey"], hash["key"], hash["secret"]).push_payment
      end
    end

    attr_reader :token, :amount, :phone_number, :till_number, :business_short_code, :callback_url, :business_passkey, :transaction_type

    def initialize(amount, phone_number, transaction_type, till_number = nil, business_short_code = nil, callback_url = nil, business_passkey = nil, key = nil, secret = nil)
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
          BusinessShortCode: get_business_short_code,
          Password: generate_password,
          Timestamp: "#{timestamp}",
          TransactionType: transaction_type,
          Amount: "#{amount}",
          PartyA: "#{phone_number}",
          PartyB: get_till_number,
          PhoneNumber: "#{phone_number}",
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
      DateTime.now.strftime("%Y%m%d%H%M%S").to_i
    end

    # shortcode
    # passkey
    # timestamp
    def generate_password
      key = "#{get_business_short_code}#{get_business_passkey}#{timestamp}"
      Base64.encode64(key).split("\n").join
    end

    def get_business_short_code
      if business_short_code.nil? || business_short_code.eql?("")
        if ENV['business_short_code'].nil? || ENV['business_short_code'].eql?("")
          raise Exception.new "Business Short Code is not defined"
        else
          ENV['business_short_code']
        end
      else
        business_short_code
      end
    end

    def get_business_passkey
      if business_passkey.nil? || business_passkey.eql?("")
        if ENV['business_passkey'].nil? || ENV['business_passkey'].eql?("")
          raise Exception.new "Business Passkey is not defined"
        else
          ENV['business_passkey']
        end
      else
        business_passkey
      end
    end

    def get_callback_url
      if callback_url.nil? || callback_url.eql?("")
        if ENV['callback_url'].nil? || ENV['callback_url'].eql?("")
          raise Exception.new "Callback URL is not defined"
        else
          ENV['callback_url']
        end
      else
        callback_url
      end
    end

    def get_till_number
      if transaction_type.eql?("CustomerPayBillOnline")
        get_business_short_code
      else
        if till_number.nil?
          if ENV['till_number'].nil? || ENV['till_number'].eql?("")
            raise Exception.new "Till number is not defined"
          else
            ENV['till_number']
          end
        else
          till_number
        end
      end
    end
  end
end