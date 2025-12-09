require "test_helper"

class PullTransactionsTest < Minitest::Test
  def setup
    @base_url = "https://sandbox.safaricom.co.ke"
    @register_url = "#{@base_url}/pulltransactions/v1/register"
    @query_url = "#{@base_url}/pulltransactions/v1/query"
    
    ENV["base_url"] = @base_url
    ENV["pull_transactions_register_url"] = "/pulltransactions/v1/register"
    ENV["pull_transactions_query_url"] = "/pulltransactions/v1/query"
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

  def test_class_register_method
    stub_register_request(success: true)
    
    hash = { "request_type" => "pull", "nominated_number" => "254712345678" }
    result = MpesaStk::PullTransactions.register(hash)
    
    refute_nil result
  end

  def test_class_query_method
    stub_query_request(success: true)
    
    result = MpesaStk::PullTransactions.query("2020-08-04 8:36:00", "2020-08-16 10:10:00", {})
    
    refute_nil result
  end

  def test_register_url_success
    stub_register_request(success: true)
    
    hash = { "request_type" => "pull", "nominated_number" => "254712345678" }
    pull = MpesaStk::PullTransactions.new(hash)
    result = pull.register_url
    
    refute_nil result
  end

  def test_query_transactions_success
    stub_query_request(success: true)
    
    pull = MpesaStk::PullTransactions.new({})
    result = pull.query_transactions("2020-08-04 8:36:00", "2020-08-16 10:10:00")
    
    refute_nil result
  end

  def test_register_body_includes_fields
    hash = { "request_type" => "pull", "nominated_number" => "254712345678" }
    pull = MpesaStk::PullTransactions.new(hash)
    body = JSON.parse(pull.send(:register_body))
    
    assert_equal ENV["business_short_code"], body["ShortCode"]
    assert_equal "pull", body["RequestType"]
    assert_equal "254712345678", body["NominatedNumber"]
  end

  def test_query_body_includes_dates
    pull = MpesaStk::PullTransactions.new({})
    body = JSON.parse(pull.send(:query_body, "2020-08-04 8:36:00", "2020-08-16 10:10:00"))
    
    assert_equal "2020-08-04 8:36:00", body["StartDate"]
    assert_equal "2020-08-16 10:10:00", body["EndDate"]
    assert_equal "0", body["OffSetValue"]
  end

  private

  def stub_register_request(success: true)
    if success
      response_body = { ResponseCode: "0", ResponseDescription: "success" }.to_json

      stub_request(:post, @register_url)
        .with(headers: { "Authorization" => "Bearer #{@access_token}" })
        .to_return(status: 200, body: response_body)
    else
      stub_request(:post, @register_url)
        .to_return(status: 400, body: { error: "Bad Request" }.to_json)
    end
  end

  def stub_query_request(success: true)
    if success
      response_body = { ResponseCode: "0", data: [] }.to_json

      stub_request(:post, @query_url)
        .with(headers: { "Authorization" => "Bearer #{@access_token}" })
        .to_return(status: 200, body: response_body)
    else
      stub_request(:post, @query_url)
        .to_return(status: 400, body: { error: "Bad Request" }.to_json)
    end
  end
end

