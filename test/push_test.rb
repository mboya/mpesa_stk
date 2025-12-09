require "test_helper"

class PushTest < Minitest::Test
  def setup
    @amount = "100"
    @phone_number = "254712345678"
    @base_url = "https://sandbox.safaricom.co.ke"
    @process_url = "#{@base_url}/mpesa/stkpush/v1/processrequest"
    
    # Setup ENV defaults
    ENV["base_url"] = @base_url
    ENV["process_request_url"] = "/mpesa/stkpush/v1/processrequest"
    ENV["business_short_code"] = "174379"
    ENV["business_passkey"] = "test_passkey"
    ENV["callback_url"] = "https://api.endpoint/callback"
    ENV["till_number"] = "174379"
    
    # Mock access token
    @access_token = "test_access_token"
    stub_access_token_request
  end

  def teardown
    WebMock.reset!
  end

  def stub_access_token_request(key: nil, secret: nil)
    token_url = "#{@base_url}/oauth/v1/generate?grant_type=client_credentials"
    stub_request(:get, token_url)
      .to_return(
        status: 200,
        body: { access_token: @access_token, expires_in: "3599" }.to_json
      )
  end

  def test_pay_bill_with_hash_parameters
    hash = {
      "business_short_code" => "123456",
      "business_passkey" => "custom_passkey",
      "callback_url" => "https://custom.callback/url",
      "key" => "custom_key",
      "secret" => "custom_secret"
    }
    
    stub_access_token_request(key: hash["key"], secret: hash["secret"])
    stub_payment_request(transaction_type: "CustomerPayBillOnline", success: true)
    
    result = MpesaStk::Push.pay_bill(@amount, @phone_number, hash)
    
    assert_equal "0", result["ResponseCode"]
  end

  def test_pay_bill_with_env_variables
    stub_payment_request(transaction_type: "CustomerPayBillOnline", success: true)
    
    result = MpesaStk::Push.pay_bill(@amount, @phone_number, {})
    
    assert_equal "0", result["ResponseCode"]
  end

  def test_buy_goods_with_hash_parameters
    hash = {
      "business_short_code" => "123456",
      "business_passkey" => "custom_passkey",
      "callback_url" => "https://custom.callback/url",
      "till_number" => "987654",
      "key" => "custom_key",
      "secret" => "custom_secret"
    }
    
    stub_access_token_request(key: hash["key"], secret: hash["secret"])
    stub_payment_request(transaction_type: "CustomerBuyGoodsOnline", success: true, till_number: hash["till_number"])
    
    result = MpesaStk::Push.buy_goods(@amount, @phone_number, hash)
    
    assert_equal "0", result["ResponseCode"]
  end

  def test_buy_goods_with_env_variables
    stub_payment_request(transaction_type: "CustomerBuyGoodsOnline", success: true)
    
    result = MpesaStk::Push.buy_goods(@amount, @phone_number, {})
    
    assert_equal "0", result["ResponseCode"]
  end

  def test_initializes_with_correct_attributes
    push = MpesaStk::Push.new(
      @amount,
      @phone_number,
      "CustomerPayBillOnline",
      nil,
      "123456",
      "https://callback.url",
      "passkey",
      "key",
      "secret"
    )
    
    assert_equal @amount, push.amount
    assert_equal @phone_number, push.phone_number
    assert_equal "CustomerPayBillOnline", push.transaction_type
    assert_equal "123456", push.business_short_code
    assert_equal "https://callback.url", push.callback_url
    assert_equal "passkey", push.business_passkey
  end

  def test_push_payment_success
    stub_payment_request(transaction_type: "CustomerPayBillOnline", success: true)
    
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline")
    result = push.push_payment
    
    assert_equal "0", result["ResponseCode"]
  end

  def test_push_payment_handles_error
    stub_payment_request(transaction_type: "CustomerPayBillOnline", success: false)
    
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline")
    
    assert_raises(StandardError) do
      push.push_payment
    end
  end

  def test_get_business_short_code_from_hash
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline", nil, "123456")
    assert_equal "123456", push.send(:get_business_short_code)
  end

  def test_get_business_short_code_from_env
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline")
    assert_equal ENV["business_short_code"], push.send(:get_business_short_code)
  end

  def test_get_business_short_code_raises_when_missing
    ENV.delete("business_short_code")
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline")
    
    assert_raises(ArgumentError, "Business Short Code is not defined") do
      push.send(:get_business_short_code)
    end
  ensure
    ENV["business_short_code"] = "174379"
  end

  def test_get_business_passkey_from_hash
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline", nil, nil, nil, "custom_passkey")
    assert_equal "custom_passkey", push.send(:get_business_passkey)
  end

  def test_get_business_passkey_from_env
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline")
    assert_equal ENV["business_passkey"], push.send(:get_business_passkey)
  end

  def test_get_business_passkey_raises_when_missing
    ENV.delete("business_passkey")
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline")
    
    assert_raises(ArgumentError, "Business Passkey is not defined") do
      push.send(:get_business_passkey)
    end
  ensure
    ENV["business_passkey"] = "test_passkey"
  end

  def test_get_callback_url_from_hash
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline", nil, nil, "https://custom.url")
    assert_equal "https://custom.url", push.send(:get_callback_url)
  end

  def test_get_callback_url_from_env
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline")
    assert_equal ENV["callback_url"], push.send(:get_callback_url)
  end

  def test_get_callback_url_raises_when_missing
    ENV.delete("callback_url")
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline")
    
    assert_raises(ArgumentError, "Callback URL is not defined") do
      push.send(:get_callback_url)
    end
  ensure
    ENV["callback_url"] = "https://api.endpoint/callback"
  end

  def test_get_till_number_for_pay_bill
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline", nil, "123456")
    till_number = push.send(:get_till_number)
    
    # For pay bill, till number should be same as business short code
    assert_equal "123456", till_number
  end

  def test_get_till_number_for_buy_goods_from_hash
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerBuyGoodsOnline", "987654", "123456")
    assert_equal "987654", push.send(:get_till_number)
  end

  def test_get_till_number_for_buy_goods_from_env
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerBuyGoodsOnline")
    assert_equal ENV["till_number"], push.send(:get_till_number)
  end

  def test_get_till_number_raises_when_missing_for_buy_goods
    ENV.delete("till_number")
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerBuyGoodsOnline")
    
    assert_raises(ArgumentError, "Till number is not defined") do
      push.send(:get_till_number)
    end
  ensure
    ENV["till_number"] = "174379"
  end

  def test_body_for_pay_bill
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline")
    body = JSON.parse(push.send(:body))
    
    assert_equal "CustomerPayBillOnline", body["TransactionType"]
    assert_equal @amount, body["Amount"]
    assert_equal @phone_number, body["PartyA"]
    assert_equal @phone_number, body["PhoneNumber"]
    assert_equal ENV["business_short_code"], body["PartyB"]
    refute_nil body["Password"]
    refute_nil body["Timestamp"]
  end

  def test_body_for_buy_goods
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerBuyGoodsOnline", "987654")
    body = JSON.parse(push.send(:body))
    
    assert_equal "CustomerBuyGoodsOnline", body["TransactionType"]
    assert_equal "987654", body["PartyB"]
  end

  def test_generate_password
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline")
    password = push.send(:generate_password)
    
    refute_nil password
    assert_instance_of String, password
    
    decoded = Base64.decode64(password)
    short_code = push.send(:get_business_short_code)
    passkey = push.send(:get_business_passkey)
    assert_match(/^#{short_code}#{passkey}\d+$/, decoded)
  end

  def test_timestamp_format
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline")
    timestamp = push.send(:timestamp)
    
    assert_instance_of Integer, timestamp
    assert_equal 14, timestamp.to_s.length
  end

  def test_generate_bill_reference_number
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline")
    ref_number = push.send(:generate_bill_reference_number, 10)
    
    assert_equal 10, ref_number.length
    assert_match(/^[A-Za-z]{10}$/, ref_number)
  end

  def test_headers_includes_authorization
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline")
    headers = push.send(:headers)
    
    assert_equal "Bearer #{@access_token}", headers["Authorization"]
    assert_equal "application/json", headers["Content-Type"]
  end

  def test_url_construction
    push = MpesaStk::Push.new(@amount, @phone_number, "CustomerPayBillOnline")
    url = push.send(:url)
    
    assert_equal @process_url, url
  end

  private

  def stub_payment_request(transaction_type:, success: true, till_number: nil)
    if success
      response_body = {
        MerchantRequestID: "7909-1302368-1",
        CheckoutRequestID: "ws_CO_DMZ_40472724_16062018092359957",
        ResponseCode: "0",
        ResponseDescription: "Success. Request accepted for processing",
        CustomerMessage: "Success. Request accepted for processing"
      }.to_json

      stub_request(:post, @process_url)
        .with(
          headers: {
            "Authorization" => "Bearer #{@access_token}",
            "Content-Type" => "application/json"
          },
          body: hash_including(
            TransactionType: transaction_type,
            Amount: @amount,
            PhoneNumber: @phone_number
          )
        )
        .to_return(status: 200, body: response_body)
    else
      stub_request(:post, @process_url)
        .to_return(status: 400, body: { errorCode: "400.001.1001", errorMessage: "Bad Request" }.to_json)
    end
  end
end

