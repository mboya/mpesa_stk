require "test_helper"

class PushPaymentTest < Minitest::Test
  def setup
    @amount = "100"
    @phone_number = "254712345678"
    @base_url = "https://sandbox.safaricom.co.ke"
    @process_url = "#{@base_url}/mpesa/stkpush/v1/processrequest"
    
    # Setup ENV
    ENV["base_url"] = @base_url
    ENV["process_request_url"] = "/mpesa/stkpush/v1/processrequest"
    ENV["business_short_code"] = "174379"
    ENV["business_passkey"] = "test_passkey"
    ENV["callback_url"] = "https://api.endpoint/callback"
    
    # Mock access token
    @access_token = "test_access_token"
    stub_access_token_request
  end

  def teardown
    WebMock.reset!
  end

  def stub_access_token_request
    token_url = "#{@base_url}/oauth/v1/generate?grant_type=client_credentials"
    stub_request(:get, token_url)
      .to_return(
        status: 200,
        body: { access_token: @access_token, expires_in: "3599" }.to_json
      )
  end

  def test_initializes_with_amount_and_phone_number
    payment = MpesaStk::PushPayment.new(@amount, @phone_number)
    assert_equal @amount, payment.amount
    assert_equal @phone_number, payment.phone_number
    refute_nil payment.token
  end

  def test_class_call_method
    stub_payment_request(success: true)
    
    result = MpesaStk::PushPayment.call(@amount, @phone_number)
    refute_nil result
    assert_equal "0", result["ResponseCode"]
  end

  def test_push_payment_success
    stub_payment_request(success: true)
    
    payment = MpesaStk::PushPayment.new(@amount, @phone_number)
    result = payment.push_payment
    
    assert_equal "0", result["ResponseCode"]
    assert_equal "Success. Request accepted for processing", result["ResponseDescription"]
    refute_nil result["MerchantRequestID"]
    refute_nil result["CheckoutRequestID"]
  end

  def test_push_payment_handles_error
    stub_payment_request(success: false)
    
    payment = MpesaStk::PushPayment.new(@amount, @phone_number)
    
    assert_raises(StandardError) do
      payment.push_payment
    end
  end

  def test_body_includes_correct_fields
    payment = MpesaStk::PushPayment.new(@amount, @phone_number)
    body = JSON.parse(payment.send(:body))
    
    assert_equal ENV["business_short_code"], body["BusinessShortCode"]
    assert_equal @amount, body["Amount"]
    assert_equal @phone_number, body["PartyA"]
    assert_equal @phone_number, body["PhoneNumber"]
    assert_equal ENV["business_short_code"], body["PartyB"]
    assert_equal ENV["callback_url"], body["CallBackURL"]
    assert_equal "CustomerPayBillOnline", body["TransactionType"]
    refute_nil body["Password"]
    refute_nil body["Timestamp"]
    refute_nil body["AccountReference"]
    refute_nil body["TransactionDesc"]
  end

  def test_generate_password
    payment = MpesaStk::PushPayment.new(@amount, @phone_number)
    password = payment.send(:generate_password)
    
    refute_nil password
    assert_instance_of String, password
    
    # Password should be base64 encoded
    decoded = Base64.decode64(password)
    assert_match(/^#{ENV["business_short_code"]}#{ENV["business_passkey"]}\d+$/, decoded)
  end

  def test_timestamp_format
    payment = MpesaStk::PushPayment.new(@amount, @phone_number)
    timestamp = payment.send(:timestamp)
    
    assert_instance_of Integer, timestamp
    assert_equal 14, timestamp.to_s.length
  end

  def test_generate_bill_reference_number
    payment = MpesaStk::PushPayment.new(@amount, @phone_number)
    ref_number = payment.send(:generate_bill_reference_number, 5)
    
    assert_equal 5, ref_number.length
    assert_match(/^[A-Za-z]{5}$/, ref_number)
  end

  def test_headers_includes_authorization
    payment = MpesaStk::PushPayment.new(@amount, @phone_number)
    headers = payment.send(:headers)
    
    assert_equal "Bearer #{@access_token}", headers["Authorization"]
    assert_equal "application/json", headers["Content-Type"]
  end

  def test_url_construction
    payment = MpesaStk::PushPayment.new(@amount, @phone_number)
    url = payment.send(:url)
    
    assert_equal @process_url, url
  end

  private

  def stub_payment_request(success: true)
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
            BusinessShortCode: ENV["business_short_code"],
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

