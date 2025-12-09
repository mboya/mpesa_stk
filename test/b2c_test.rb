require "test_helper"

class B2CTest < Minitest::Test
  def setup
    @amount = "500"
    @phone_number = "254712345678"
    @base_url = "https://sandbox.safaricom.co.ke"
    @b2c_url = "#{@base_url}/mpesa/b2c/v1/paymentrequest"
    
    ENV["base_url"] = @base_url
    ENV["b2c_url"] = "/mpesa/b2c/v1/paymentrequest"
    ENV["business_short_code"] = "174379"
    ENV["initiator_name"] = "testapi"
    ENV["security_credential"] = "encrypted_credential"
    ENV["result_url"] = "https://api.endpoint/result"
    ENV["queue_timeout_url"] = "https://api.endpoint/queue_timeout"
    
    @access_token = "test_access_token"
    stub_access_token_request
  end

  def teardown
    WebMock.reset!
  end

  def stub_access_token_request
    token_url = "#{@base_url}/oauth/v1/generate?grant_type=client_credentials"
    stub_request(:get, token_url)
      .to_return(status: 200, body: { access_token: @access_token, expires_in: "3599" }.to_json)
  end

  def test_class_pay_method
    stub_b2c_request(success: true)
    
    result = MpesaStk::B2C.pay(@amount, @phone_number, {})
    
    refute_nil result
    assert_equal "0", result["ResponseCode"]
  end

  def test_initializes_with_amount_and_phone
    b2c = MpesaStk::B2C.new(@amount, @phone_number, {})
    assert_equal @amount, b2c.amount
    assert_equal @phone_number, b2c.phone_number
  end

  def test_send_payment_success
    stub_b2c_request(success: true)
    
    b2c = MpesaStk::B2C.new(@amount, @phone_number, {})
    result = b2c.send_payment
    
    assert_equal "0", result["ResponseCode"]
  end

  def test_body_includes_all_fields
    b2c = MpesaStk::B2C.new(@amount, @phone_number, {})
    body = JSON.parse(b2c.send(:body))
    
    assert_equal "BusinessPayment", body["CommandID"]
    assert_equal @amount, body["Amount"]
    assert_equal @phone_number, body["PartyB"]
    assert_equal ENV["business_short_code"], body["PartyA"]
  end

  def test_supports_custom_command_id
    hash = { "command_id" => "SalaryPayment" }
    b2c = MpesaStk::B2C.new(@amount, @phone_number, hash)
    body = JSON.parse(b2c.send(:body))
    
    assert_equal "SalaryPayment", body["CommandID"]
  end

  def test_supports_occasion
    hash = { "occasion" => "Birthday" }
    b2c = MpesaStk::B2C.new(@amount, @phone_number, hash)
    body = JSON.parse(b2c.send(:body))
    
    assert_equal "Birthday", body["Occasion"]
  end

  private

  def stub_b2c_request(success: true)
    if success
      response_body = {
        ResponseCode: "0",
        ResponseDescription: "The service request is processed successfully.",
        OriginatorConversationID: "12345-67890-1",
        ConversationID: "AG_20240101_12345678901234567890"
      }.to_json

      stub_request(:post, @b2c_url)
        .with(headers: { "Authorization" => "Bearer #{@access_token}" })
        .to_return(status: 200, body: response_body)
    else
      stub_request(:post, @b2c_url)
        .to_return(status: 400, body: { errorCode: "400.001.1001" }.to_json)
    end
  end
end

