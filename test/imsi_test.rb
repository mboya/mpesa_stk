require "test_helper"

class IMSITest < Minitest::Test
  def setup
    @customer_number = "254712345678"
    @base_url = "https://sandbox.safaricom.co.ke"
    @imsi_v1_url = "#{@base_url}/imsi/v1/checkATI"
    @imsi_v2_url = "#{@base_url}/imsi/v2/checkATI"
    
    ENV["base_url"] = @base_url
    
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

  def test_class_check_ati_method_v1
    stub_imsi_request(@imsi_v1_url, success: true)
    
    result = MpesaStk::IMSI.check_ati(@customer_number, {})
    
    refute_nil result
  end

  def test_class_check_ati_method_v2
    stub_imsi_request(@imsi_v2_url, success: true)
    
    result = MpesaStk::IMSI.check_ati(@customer_number, {}, version: "v2")
    
    refute_nil result
  end

  def test_check_ati_v1_success
    stub_imsi_request(@imsi_v1_url, success: true)
    
    imsi = MpesaStk::IMSI.new({})
    result = imsi.check_ati(@customer_number, "v1")
    
    refute_nil result
  end

  def test_check_ati_v2_success
    stub_imsi_request(@imsi_v2_url, success: true)
    
    imsi = MpesaStk::IMSI.new({})
    result = imsi.check_ati(@customer_number, "v2")
    
    refute_nil result
  end

  def test_body_includes_customer_number
    imsi = MpesaStk::IMSI.new({})
    body = JSON.parse(imsi.send(:body, @customer_number))
    
    assert_equal @customer_number, body["customerNumber"]
  end

  private

  def stub_imsi_request(url, success: true)
    if success
      response_body = { success: true, data: {} }.to_json

      stub_request(:post, url)
        .with(headers: { "Authorization" => "Bearer #{@access_token}" })
        .to_return(status: 200, body: response_body)
    else
      stub_request(:post, url)
        .to_return(status: 400, body: { error: "Bad Request" }.to_json)
    end
  end
end

