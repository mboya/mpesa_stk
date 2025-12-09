require "test_helper"

class StkPushQueryTest < Minitest::Test
  def setup
    @checkout_request_id = "ws_CO_DMZ_40472724_16062018092359957"
    @base_url = "https://sandbox.safaricom.co.ke"
    @query_url = "#{@base_url}/mpesa/stkpushquery/v1/query"
    
    ENV["base_url"] = @base_url
    ENV["stk_push_query_url"] = "/mpesa/stkpushquery/v1/query"
    ENV["business_short_code"] = "174379"
    ENV["business_passkey"] = "test_passkey"
    
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
    stub_query_request(success: true)
    
    result = MpesaStk::StkPushQuery.query(@checkout_request_id, {})
    
    refute_nil result
    assert_equal "0", result["ResponseCode"]
  end

  def test_initializes_with_checkout_request_id
    query = MpesaStk::StkPushQuery.new(@checkout_request_id, {})
    assert_equal @checkout_request_id, query.checkout_request_id
    refute_nil query.token
  end

  def test_query_status_success
    stub_query_request(success: true)
    
    query = MpesaStk::StkPushQuery.new(@checkout_request_id, {})
    result = query.query_status
    
    assert_equal "0", result["ResponseCode"]
  end

  def test_query_status_handles_error
    stub_query_request(success: false)
    
    query = MpesaStk::StkPushQuery.new(@checkout_request_id, {})
    
    assert_raises(StandardError) do
      query.query_status
    end
  end

  def test_body_includes_all_required_fields
    query = MpesaStk::StkPushQuery.new(@checkout_request_id, {})
    body = JSON.parse(query.send(:body))
    
    assert_equal ENV["business_short_code"], body["BusinessShortCode"]
    assert_equal @checkout_request_id, body["CheckoutRequestID"]
    refute_nil body["Password"]
    refute_nil body["Timestamp"]
  end

  def test_generate_password
    query = MpesaStk::StkPushQuery.new(@checkout_request_id, {})
    password = query.send(:generate_password)
    
    refute_nil password
    decoded = Base64.decode64(password)
    assert_match(/^#{ENV["business_short_code"]}#{ENV["business_passkey"]}\d+$/, decoded)
  end

  def test_get_business_short_code_raises_when_missing
    ENV.delete("business_short_code")
    query = MpesaStk::StkPushQuery.new(@checkout_request_id, {})
    
    assert_raises(ArgumentError) do
      query.send(:get_business_short_code)
    end
  ensure
    ENV["business_short_code"] = "174379"
  end

  private

  def stub_query_request(success: true)
    if success
      response_body = {
        ResponseCode: "0",
        ResponseDescription: "The service request is processed successfully.",
        MerchantRequestID: "7909-1302368-1",
        CheckoutRequestID: @checkout_request_id
      }.to_json

      stub_request(:post, @query_url)
        .with(headers: { "Authorization" => "Bearer #{@access_token}" })
        .to_return(status: 200, body: response_body)
    else
      stub_request(:post, @query_url)
        .to_return(status: 400, body: { errorCode: "400.001.1001" }.to_json)
    end
  end
end

