require "test_helper"

class RatibaTest < Minitest::Test
  def setup
    @base_url = "https://sandbox.safaricom.co.ke"
    @ratiba_url = "#{@base_url}/standingorder/v1/createStandingOrderExternal"
    
    ENV["base_url"] = @base_url
    ENV["ratiba_url"] = "/standingorder/v1/createStandingOrderExternal"
    ENV["business_short_code"] = "174379"
    ENV["callback_url"] = "https://api.endpoint/callback"
    
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

  def test_class_create_standing_order_method
    stub_ratiba_request(success: true)
    
    hash = {
      "amount" => "500",
      "party_a" => "254712345678",
      "start_date" => "2025-09-25",
      "end_date" => "2026-09-25"
    }
    
    result = MpesaStk::Ratiba.create_standing_order(hash)
    
    refute_nil result
    assert_equal "0", result["ResponseCode"]
  end

  def test_create_success
    stub_ratiba_request(success: true)
    
    hash = {
      "amount" => "500",
      "party_a" => "254712345678",
      "start_date" => "2025-09-25",
      "end_date" => "2026-09-25"
    }
    
    ratiba = MpesaStk::Ratiba.new(hash)
    result = ratiba.create
    
    assert_equal "0", result["ResponseCode"]
  end

  def test_body_includes_all_fields
    hash = {
      "amount" => "500",
      "party_a" => "254712345678",
      "start_date" => "2025-09-25",
      "end_date" => "2026-09-25",
      "frequency" => "3"
    }
    
    ratiba = MpesaStk::Ratiba.new(hash)
    body = JSON.parse(ratiba.send(:body))
    
    assert_equal "500", body["Amount"]
    assert_equal "254712345678", body["PartyA"]
    assert_equal "3", body["Frequency"]
    assert_equal "2025-09-25", body["StartDate"]
    assert_equal "2026-09-25", body["EndDate"]
  end

  def test_supports_buy_goods_transaction_type
    hash = {
      "amount" => "500",
      "party_a" => "254712345678",
      "transaction_type" => "Standing Order Customer Pay Merchant",
      "receiver_party_identifier_type" => "2",
      "start_date" => "2025-09-25",
      "end_date" => "2026-09-25"
    }
    
    ratiba = MpesaStk::Ratiba.new(hash)
    body = JSON.parse(ratiba.send(:body))
    
    assert_equal "Standing Order Customer Pay Merchant", body["TransactionType"]
    assert_equal "2", body["ReceiverPartyIdentifierType"]
  end

  private

  def stub_ratiba_request(success: true)
    if success
      response_body = {
        ResponseCode: "0",
        ResponseDescription: "The service request is processed successfully.",
        OriginatorConversationID: "12345-67890-1",
        ConversationID: "AG_20240101_12345678901234567890"
      }.to_json

      stub_request(:post, @ratiba_url)
        .with(headers: { "Authorization" => "Bearer #{@access_token}" })
        .to_return(status: 200, body: response_body)
    else
      stub_request(:post, @ratiba_url)
        .to_return(status: 400, body: { errorCode: "400.001.1001" }.to_json)
    end
  end
end

