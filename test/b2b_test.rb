require "test_helper"

class B2BTest < Minitest::Test
  def setup
    @amount = "1000"
    @receiver_party = "123456"
    @base_url = "https://sandbox.safaricom.co.ke"
    @b2b_url = "#{@base_url}/mpesa/b2b/v1/paymentrequest"
    
    ENV["base_url"] = @base_url
    ENV["b2b_url"] = "/mpesa/b2b/v1/paymentrequest"
    ENV["business_short_code"] = "174379"
    ENV["initiator"] = "testapi"
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
    stub_b2b_request(success: true)
    
    result = MpesaStk::B2B.pay(@amount, @receiver_party, {})
    
    refute_nil result
    assert_equal "0", result["ResponseCode"]
  end

  def test_send_payment_success
    stub_b2b_request(success: true)
    
    b2b = MpesaStk::B2B.new(@amount, @receiver_party, {})
    result = b2b.send_payment
    
    assert_equal "0", result["ResponseCode"]
  end

  def test_body_includes_all_fields
    b2b = MpesaStk::B2B.new(@amount, @receiver_party, {})
    body = JSON.parse(b2b.send(:body))
    
    assert_equal "BusinessPayBill", body["CommandID"]
    assert_equal @amount, body["Amount"]
    assert_equal @receiver_party, body["PartyB"]
    assert_equal "4", body["SenderIdentifierType"]
    assert_equal "4", body["RecieverIdentifierType"]
  end

  def test_supports_till_number_receiver
    hash = { "receiver_identifier_type" => "2" }
    b2b = MpesaStk::B2B.new(@amount, @receiver_party, hash)
    assert_equal "2", b2b.receiver_identifier_type
  end

  private

  def stub_b2b_request(success: true)
    if success
      response_body = {
        ResponseCode: "0",
        ResponseDescription: "The service request is processed successfully.",
        OriginatorConversationID: "12345-67890-1",
        ConversationID: "AG_20240101_12345678901234567890"
      }.to_json

      stub_request(:post, @b2b_url)
        .with(headers: { "Authorization" => "Bearer #{@access_token}" })
        .to_return(status: 200, body: response_body)
    else
      stub_request(:post, @b2b_url)
        .to_return(status: 400, body: { errorCode: "400.001.1001" }.to_json)
    end
  end
end

