require "test_helper"

class TransactionStatusTest < Minitest::Test
  def setup
    @transaction_id = "OFR4Z5EE9Y"
    @base_url = "https://sandbox.safaricom.co.ke"
    @transaction_status_url = "#{@base_url}/mpesa/transactionstatus/v1/query"
    
    # Setup ENV defaults
    ENV["base_url"] = @base_url
    ENV["transaction_status_url"] = "/mpesa/transactionstatus/v1/query"
    ENV["business_short_code"] = "174379"
    ENV["initiator"] = "testapi"
    ENV["security_credential"] = "encrypted_security_credential"
    ENV["result_url"] = "https://api.endpoint/result"
    ENV["queue_timeout_url"] = "https://api.endpoint/queue_timeout"
    
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

  def test_class_query_method
    stub_transaction_status_request(success: true)
    
    result = MpesaStk::TransactionStatus.query(@transaction_id, {})
    
    refute_nil result
    assert_equal "0", result["ResponseCode"]
  end

  def test_initializes_with_transaction_id
    status = MpesaStk::TransactionStatus.new(@transaction_id, {})
    assert_equal @transaction_id, status.transaction_id
    refute_nil status.token
  end

  def test_initializes_with_hash_parameters
    hash = {
      "initiator" => "custom_initiator",
      "security_credential" => "custom_security",
      "party_a" => "123456",
      "result_url" => "https://custom.result/url",
      "queue_timeout_url" => "https://custom.queue/url",
      "identifier_type" => "4",
      "key" => "custom_key",
      "secret" => "custom_secret"
    }
    
    stub_access_token_request(key: hash["key"], secret: hash["secret"])
    status = MpesaStk::TransactionStatus.new(@transaction_id, hash)
    
    assert_equal hash["initiator"], status.initiator
    assert_equal hash["security_credential"], status.security_credential
    assert_equal hash["party_a"], status.party_a
    assert_equal hash["result_url"], status.result_url
    assert_equal hash["queue_timeout_url"], status.queue_timeout_url
    assert_equal hash["identifier_type"], status.identifier_type
  end

  def test_query_status_success
    stub_transaction_status_request(success: true)
    
    status = MpesaStk::TransactionStatus.new(@transaction_id, {})
    result = status.query_status
    
    assert_equal "0", result["ResponseCode"]
    assert_equal "The service request is processed successfully.", result["ResponseDescription"]
    refute_nil result["ConversationID"]
    refute_nil result["OriginatorConversationID"]
  end

  def test_query_status_handles_error
    stub_transaction_status_request(success: false)
    
    status = MpesaStk::TransactionStatus.new(@transaction_id, {})
    
    assert_raises(StandardError) do
      status.query_status
    end
  end

  def test_body_includes_all_required_fields
    status = MpesaStk::TransactionStatus.new(@transaction_id, {})
    body = JSON.parse(status.send(:body))
    
    assert_equal "TransactionStatusQuery", body["CommandID"]
    assert_equal @transaction_id, body["TransactionID"]
    assert_equal ENV["initiator"], body["Initiator"]
    assert_equal ENV["security_credential"], body["SecurityCredential"]
    assert_equal ENV["business_short_code"], body["PartyA"]
    assert_equal "4", body["IdentifierType"]
    assert_equal ENV["result_url"], body["ResultURL"]
    assert_equal ENV["queue_timeout_url"], body["QueueTimeOutURL"]
  end

  def test_get_initiator_from_hash
    hash = { "initiator" => "custom_initiator" }
    status = MpesaStk::TransactionStatus.new(@transaction_id, hash)
    assert_equal "custom_initiator", status.send(:get_initiator)
  end

  def test_get_initiator_from_env
    status = MpesaStk::TransactionStatus.new(@transaction_id, {})
    assert_equal ENV["initiator"], status.send(:get_initiator)
  end

  def test_get_initiator_raises_when_missing
    ENV.delete("initiator")
    status = MpesaStk::TransactionStatus.new(@transaction_id, {})
    
    assert_raises(ArgumentError, "Initiator is not defined") do
      status.send(:get_initiator)
    end
  ensure
    ENV["initiator"] = "testapi"
  end

  def test_get_security_credential_from_hash
    hash = { "security_credential" => "custom_security" }
    status = MpesaStk::TransactionStatus.new(@transaction_id, hash)
    assert_equal "custom_security", status.send(:get_security_credential)
  end

  def test_get_security_credential_from_env
    status = MpesaStk::TransactionStatus.new(@transaction_id, {})
    assert_equal ENV["security_credential"], status.send(:get_security_credential)
  end

  def test_get_security_credential_raises_when_missing
    ENV.delete("security_credential")
    status = MpesaStk::TransactionStatus.new(@transaction_id, {})
    
    assert_raises(ArgumentError, "Security Credential is not defined") do
      status.send(:get_security_credential)
    end
  ensure
    ENV["security_credential"] = "encrypted_security_credential"
  end

  def test_get_party_a_from_hash
    hash = { "party_a" => "123456" }
    status = MpesaStk::TransactionStatus.new(@transaction_id, hash)
    assert_equal "123456", status.send(:get_party_a)
  end

  def test_get_party_a_from_env
    status = MpesaStk::TransactionStatus.new(@transaction_id, {})
    assert_equal ENV["business_short_code"], status.send(:get_party_a)
  end

  def test_get_party_a_raises_when_missing
    ENV.delete("business_short_code")
    status = MpesaStk::TransactionStatus.new(@transaction_id, {})
    
    assert_raises(ArgumentError, "PartyA (Business Short Code) is not defined") do
      status.send(:get_party_a)
    end
  ensure
    ENV["business_short_code"] = "174379"
  end

  def test_get_result_url_from_hash
    hash = { "result_url" => "https://custom.result/url" }
    status = MpesaStk::TransactionStatus.new(@transaction_id, hash)
    assert_equal "https://custom.result/url", status.send(:get_result_url)
  end

  def test_get_result_url_from_env
    status = MpesaStk::TransactionStatus.new(@transaction_id, {})
    assert_equal ENV["result_url"], status.send(:get_result_url)
  end

  def test_get_result_url_raises_when_missing
    ENV.delete("result_url")
    status = MpesaStk::TransactionStatus.new(@transaction_id, {})
    
    assert_raises(ArgumentError, "Result URL is not defined") do
      status.send(:get_result_url)
    end
  ensure
    ENV["result_url"] = "https://api.endpoint/result"
  end

  def test_get_queue_timeout_url_from_hash
    hash = { "queue_timeout_url" => "https://custom.queue/url" }
    status = MpesaStk::TransactionStatus.new(@transaction_id, hash)
    assert_equal "https://custom.queue/url", status.send(:get_queue_timeout_url)
  end

  def test_get_queue_timeout_url_from_env
    status = MpesaStk::TransactionStatus.new(@transaction_id, {})
    assert_equal ENV["queue_timeout_url"], status.send(:get_queue_timeout_url)
  end

  def test_get_queue_timeout_url_raises_when_missing
    ENV.delete("queue_timeout_url")
    status = MpesaStk::TransactionStatus.new(@transaction_id, {})
    
    assert_raises(ArgumentError, "Queue Timeout URL is not defined") do
      status.send(:get_queue_timeout_url)
    end
  ensure
    ENV["queue_timeout_url"] = "https://api.endpoint/queue_timeout"
  end

  def test_identifier_type_defaults_to_four
    status = MpesaStk::TransactionStatus.new(@transaction_id, {})
    assert_equal "4", status.identifier_type
  end

  def test_identifier_type_can_be_customized
    hash = { "identifier_type" => "1" }
    status = MpesaStk::TransactionStatus.new(@transaction_id, hash)
    assert_equal "1", status.identifier_type
  end

  def test_headers_includes_authorization
    status = MpesaStk::TransactionStatus.new(@transaction_id, {})
    headers = status.send(:headers)
    
    assert_equal "Bearer #{@access_token}", headers["Authorization"]
    assert_equal "application/json", headers["Content-Type"]
  end

  def test_url_construction
    status = MpesaStk::TransactionStatus.new(@transaction_id, {})
    url = status.send(:url)
    
    assert_equal @transaction_status_url, url
  end

  private

  def stub_transaction_status_request(success: true)
    if success
      response_body = {
        ResponseCode: "0",
        ResponseDescription: "The service request is processed successfully.",
        ConversationID: "AG_20240101_12345678901234567890",
        OriginatorConversationID: "12345-67890-1"
      }.to_json

      stub_request(:post, @transaction_status_url)
        .with(
          headers: {
            "Authorization" => "Bearer #{@access_token}",
            "Content-Type" => "application/json"
          },
          body: hash_including(
            CommandID: "TransactionStatusQuery",
            TransactionID: @transaction_id,
            IdentifierType: "4"
          )
        )
        .to_return(status: 200, body: response_body)
    else
      stub_request(:post, @transaction_status_url)
        .to_return(status: 400, body: { errorCode: "400.001.1001", errorMessage: "Bad Request" }.to_json)
    end
  end
end

