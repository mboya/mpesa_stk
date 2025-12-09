require "test_helper"

class AccountBalanceTest < Minitest::Test
  def setup
    @base_url = "https://sandbox.safaricom.co.ke"
    @balance_url = "#{@base_url}/mpesa/accountbalance/v1/query"
    
    ENV["base_url"] = @base_url
    ENV["account_balance_url"] = "/mpesa/accountbalance/v1/query"
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

  def test_class_query_method
    stub_balance_request(success: true)
    
    result = MpesaStk::AccountBalance.query({})
    
    refute_nil result
    assert_equal "0", result["ResponseCode"]
  end

  def test_query_balance_success
    stub_balance_request(success: true)
    
    balance = MpesaStk::AccountBalance.new({})
    result = balance.query_balance
    
    assert_equal "0", result["ResponseCode"]
  end

  def test_body_includes_all_fields
    balance = MpesaStk::AccountBalance.new({})
    body = JSON.parse(balance.send(:body))
    
    assert_equal "AccountBalance", body["CommandID"]
    assert_equal ENV["business_short_code"], body["PartyA"]
    assert_equal "4", body["IdentifierType"]
  end

  private

  def stub_balance_request(success: true)
    if success
      response_body = {
        ResponseCode: "0",
        ResponseDescription: "The service request is processed successfully.",
        OriginatorConversationID: "12345-67890-1",
        ConversationID: "AG_20240101_12345678901234567890"
      }.to_json

      stub_request(:post, @balance_url)
        .with(headers: { "Authorization" => "Bearer #{@access_token}" })
        .to_return(status: 200, body: response_body)
    else
      stub_request(:post, @balance_url)
        .to_return(status: 400, body: { errorCode: "400.001.1001" }.to_json)
    end
  end
end

