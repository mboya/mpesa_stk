require "test_helper"

class C2BTest < Minitest::Test
  def setup
    @base_url = "https://sandbox.safaricom.co.ke"
    @register_url = "#{@base_url}/mpesa/c2b/v1/registerurl"
    @simulate_url = "#{@base_url}/mpesa/c2b/v1/simulate"
    
    ENV["base_url"] = @base_url
    ENV["c2b_register_url"] = "/mpesa/c2b/v1/registerurl"
    ENV["c2b_simulate_url"] = "/mpesa/c2b/v1/simulate"
    ENV["business_short_code"] = "174379"
    ENV["confirmation_url"] = "https://api.endpoint/confirmation"
    
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

  def test_class_register_url_method
    stub_register_request(success: true)
    
    result = MpesaStk::C2B.register_url({})
    
    refute_nil result
    assert_equal "0", result["ResponseCode"]
  end

  def test_class_simulate_method
    stub_simulate_request(success: true)
    
    result = MpesaStk::C2B.simulate("100", "254712345678", {})
    
    refute_nil result
    assert_equal "0", result["ResponseCode"]
  end

  def test_register_success
    stub_register_request(success: true)
    
    c2b = MpesaStk::C2B.new({})
    result = c2b.register
    
    assert_equal "0", result["ResponseCode"]
  end

  def test_simulate_payment_success
    stub_simulate_request(success: true)
    
    c2b = MpesaStk::C2B.new({})
    result = c2b.simulate_payment("100", "254712345678")
    
    assert_equal "0", result["ResponseCode"]
  end

  def test_register_body_includes_required_fields
    c2b = MpesaStk::C2B.new({})
    body = JSON.parse(c2b.send(:register_body))
    
    assert_equal ENV["business_short_code"], body["ShortCode"]
    assert_equal "Completed", body["ResponseType"]
    assert_equal ENV["confirmation_url"], body["ConfirmationURL"]
  end

  def test_simulate_body_includes_all_fields
    c2b = MpesaStk::C2B.new({})
    body = JSON.parse(c2b.send(:simulate_body, "100", "254712345678"))
    
    assert_equal ENV["business_short_code"], body["ShortCode"]
    assert_equal "CustomerPayBillOnline", body["CommandID"]
    assert_equal "100", body["Amount"]
    assert_equal "254712345678", body["Msisdn"]
  end

  def test_supports_validation_url
    hash = { "validation_url" => "https://api.endpoint/validate" }
    c2b = MpesaStk::C2B.new(hash)
    body = JSON.parse(c2b.send(:register_body))
    
    assert_equal "https://api.endpoint/validate", body["ValidationURL"]
  end

  private

  def stub_register_request(success: true)
    if success
      response_body = {
        ResponseCode: "0",
        ResponseDescription: "success"
      }.to_json

      stub_request(:post, @register_url)
        .with(headers: { "Authorization" => "Bearer #{@access_token}" })
        .to_return(status: 200, body: response_body)
    else
      stub_request(:post, @register_url)
        .to_return(status: 400, body: { errorCode: "400.001.1001" }.to_json)
    end
  end

  def stub_simulate_request(success: true)
    if success
      response_body = {
        ResponseCode: "0",
        ResponseDescription: "Accept the service request successfully."
      }.to_json

      stub_request(:post, @simulate_url)
        .with(headers: { "Authorization" => "Bearer #{@access_token}" })
        .to_return(status: 200, body: response_body)
    else
      stub_request(:post, @simulate_url)
        .to_return(status: 400, body: { errorCode: "400.001.1001" }.to_json)
    end
  end
end

