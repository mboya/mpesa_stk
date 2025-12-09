require "test_helper"

class ReversalTest < Minitest::Test
  def setup
    @transaction_id = "OFR4Z5EE9Y"
    @amount = "100"
    @base_url = "https://sandbox.safaricom.co.ke"
    @reversal_url = "#{@base_url}/mpesa/reversal/v1/request"
    
    ENV["base_url"] = @base_url
    ENV["reversal_url"] = "/mpesa/reversal/v1/request"
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

  def test_class_reverse_method
    stub_reversal_request(success: true)
    
    result = MpesaStk::Reversal.reverse(@transaction_id, @amount, {})
    
    refute_nil result
    assert_equal "0", result["ResponseCode"]
  end

  def test_reverse_transaction_success
    stub_reversal_request(success: true)
    
    reversal = MpesaStk::Reversal.new(@transaction_id, @amount, {})
    result = reversal.reverse_transaction
    
    assert_equal "0", result["ResponseCode"]
  end

  def test_body_includes_all_fields
    reversal = MpesaStk::Reversal.new(@transaction_id, @amount, {})
    body = JSON.parse(reversal.send(:body))
    
    assert_equal "TransactionReversal", body["CommandID"]
    assert_equal @transaction_id, body["TransactionID"]
    assert_equal @amount, body["Amount"]
    assert_equal ENV["business_short_code"], body["ReceiverParty"]
  end

  private

  def stub_reversal_request(success: true)
    if success
      response_body = {
        ResponseCode: "0",
        ResponseDescription: "The service request is processed successfully.",
        OriginatorConversationID: "12345-67890-1",
        ConversationID: "AG_20240101_12345678901234567890"
      }.to_json

      stub_request(:post, @reversal_url)
        .with(headers: { "Authorization" => "Bearer #{@access_token}" })
        .to_return(status: 200, body: response_body)
    else
      stub_request(:post, @reversal_url)
        .to_return(status: 400, body: { errorCode: "400.001.1001" }.to_json)
    end
  end
end

