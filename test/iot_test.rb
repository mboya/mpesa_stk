require "test_helper"

class IoTTest < Minitest::Test
  def setup
    @base_url = "https://sandbox.safaricom.co.ke"
    @iot_base = "#{@base_url}/simportal/v1"
    
    ENV["base_url"] = @base_url
    ENV["iot_base_url"] = "/simportal/v1"
    ENV["iot_api_key"] = "Yl4S3KEcr173mbeUdYdjf147IuG3rJ824ArMkP6Z"
    ENV["vpn_group"] = "test_group"
    ENV["username"] = "test_user"
    
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

  def test_sims_class_method
    iot = MpesaStk::IoT.sims({})
    assert_instance_of MpesaStk::IoT, iot
  end

  def test_messaging_class_method
    iot = MpesaStk::IoT.messaging({})
    assert_instance_of MpesaStk::IoT, iot
  end

  def test_get_all_sims
    stub_iot_request("/allsims", success: true)
    
    iot = MpesaStk::IoT.sims({})
    result = iot.get_all_sims
    
    refute_nil result
  end

  def test_query_lifecycle_status
    stub_iot_request("/queryLifeCycleStatus", success: true)
    
    iot = MpesaStk::IoT.sims({})
    result = iot.query_lifecycle_status("0110100606")
    
    refute_nil result
  end

  def test_send_single_message
    stub_iot_request("/sendsinglemessage", success: true)
    
    messaging = MpesaStk::IoT.messaging({})
    result = messaging.send_single_message("0110100606", "Test message")
    
    refute_nil result
  end

  def test_headers_include_required_fields
    iot = MpesaStk::IoT.new({})
    headers = iot.send(:headers, msisdn: "0110100606")
    
    assert_equal "Bearer #{@access_token}", headers["Authorization"]
    assert_equal ENV["iot_api_key"], headers["x-api-key"]
    assert_equal "web-portal", headers["x-source-system"]
    assert_equal "0110100606", headers["X-MSISDN"]
  end

  private

  def stub_iot_request(endpoint, success: true)
    if success
      response_body = { success: true, data: [] }.to_json

      stub_request(:post, "#{@iot_base}#{endpoint}")
        .with(headers: { "Authorization" => "Bearer #{@access_token}" })
        .to_return(status: 200, body: response_body)
    else
      stub_request(:post, "#{@iot_base}#{endpoint}")
        .to_return(status: 400, body: { error: "Bad Request" }.to_json)
    end
  end
end

