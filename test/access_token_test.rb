require "test_helper"

class AccessTokenTest < Minitest::Test
  def setup
    @key = "test_key"
    @secret = "test_secret"
    @base_url = "https://sandbox.safaricom.co.ke"
    @token_url = "#{@base_url}/oauth/v1/generate?grant_type=client_credentials"
    
    # Clear Redis mock
    redis = Redis.new
    redis.clear
    
    # Setup ENV
    ENV["key"] = @key
    ENV["secret"] = @secret
    ENV["base_url"] = @base_url
    ENV["token_generator_url"] = "/oauth/v1/generate?grant_type=client_credentials"
  end

  def teardown
    WebMock.reset!
  end

  def test_initializes_with_env_variables
    token = MpesaStk::AccessToken.new
    assert_equal @key, token.instance_variable_get(:@key)
    assert_equal @secret, token.instance_variable_get(:@secret)
  end

  def test_initializes_with_provided_credentials
    custom_key = "custom_key"
    custom_secret = "custom_secret"
    token = MpesaStk::AccessToken.new(custom_key, custom_secret)
    assert_equal custom_key, token.instance_variable_get(:@key)
    assert_equal custom_secret, token.instance_variable_get(:@secret)
  end

  def test_has_token_returns_false_when_no_token
    token = MpesaStk::AccessToken.new
    assert_equal false, token.token?
  end

  def test_has_token_returns_true_when_token_exists
    token = MpesaStk::AccessToken.new
    token.instance_variable_set(:@token, "test_token")
    assert_equal true, token.token?
  end

  def test_token_expired_returns_true_when_expired
    token = MpesaStk::AccessToken.new
    token.instance_variable_set(:@timestamp, Time.now.to_i - 3600)
    token.instance_variable_set(:@expires_in, 3600)
    assert_equal true, token.token_expired?
  end

  def test_token_expired_returns_false_when_not_expired
    token = MpesaStk::AccessToken.new
    token.instance_variable_set(:@timestamp, Time.now.to_i)
    token.instance_variable_set(:@expires_in, 3600)
    assert_equal false, token.token_expired?
  end

  def test_is_valid_returns_false_when_no_token
    token = MpesaStk::AccessToken.new
    assert_equal false, token.valid?
  end

  def test_is_valid_returns_false_when_token_expired
    token = MpesaStk::AccessToken.new
    token.instance_variable_set(:@token, "test_token")
    token.instance_variable_set(:@timestamp, Time.now.to_i - 3600)
    token.instance_variable_set(:@expires_in, 3600)
    assert_equal false, token.valid?
  end

  def test_is_valid_returns_true_when_token_valid
    token = MpesaStk::AccessToken.new
    token.instance_variable_set(:@token, "test_token")
    token.instance_variable_set(:@timestamp, Time.now.to_i)
    token.instance_variable_set(:@expires_in, 3600)
    assert_equal true, token.valid?
  end

  def test_new_access_token_success
    response_body = {
      access_token: "test_access_token",
      expires_in: "3599"
    }.to_json

    stub_request(:get, @token_url)
      .with(headers: { "Authorization" => /^Basic / })
      .to_return(status: 200, body: response_body)

    token = MpesaStk::AccessToken.new
    token.new_access_token

    # Verify token was saved to Redis
    redis = Redis.new
    saved_data = redis.get(@key)
    refute_nil saved_data
    
    parsed = JSON.parse(saved_data)
    assert_equal "test_access_token", parsed["access_token"]
    assert_equal "3599", parsed["expires_in"]
    refute_nil parsed["time_stamp"]
  end

  def test_new_access_token_handles_http_error
    stub_request(:get, @token_url)
      .to_return(status: 401, body: "Unauthorized")

    token = MpesaStk::AccessToken.new
    assert_raises(StandardError) do
      token.new_access_token
    end
  end

  def test_access_token_returns_cached_token_when_valid
    token = MpesaStk::AccessToken.new
    token.instance_variable_set(:@token, "cached_token")
    token.instance_variable_set(:@timestamp, Time.now.to_i)
    token.instance_variable_set(:@expires_in, 3600)

    assert_equal "cached_token", token.access_token
  end

  def test_access_token_refreshes_when_expired
    response_body = {
      access_token: "new_access_token",
      expires_in: "3599"
    }.to_json

    stub_request(:get, @token_url)
      .with(headers: { "Authorization" => /^Basic / })
      .to_return(status: 200, body: response_body)

    token = MpesaStk::AccessToken.new
    token.instance_variable_set(:@token, "old_token")
    token.instance_variable_set(:@timestamp, Time.now.to_i - 3600)
    token.instance_variable_set(:@expires_in, 3600)

    new_token = token.access_token
    refute_equal "old_token", new_token
  end

  def test_refresh_updates_token
    response_body = {
      access_token: "refreshed_token",
      expires_in: "3599"
    }.to_json

    stub_request(:get, @token_url)
      .with(headers: { "Authorization" => /^Basic / })
      .to_return(status: 200, body: response_body)

    token = MpesaStk::AccessToken.new
    token.refresh

    redis = Redis.new
    saved_data = redis.get(@key)
    refute_nil saved_data
    
    parsed = JSON.parse(saved_data)
    assert_equal "refreshed_token", parsed["access_token"]
  end

  def test_load_from_redis_loads_existing_token
    # Set up token data in Redis before creating AccessToken instance
    redis = Redis.new
    token_data = {
      "access_token" => "redis_token",
      "expires_in" => "3599",
      "time_stamp" => Time.now.to_i
    }.to_json
    redis.set(@key, token_data)

    token = MpesaStk::AccessToken.new
    assert_equal "redis_token", token.instance_variable_get(:@token)
  end

  def test_load_from_redis_handles_empty_redis
    redis = Redis.new
    redis.clear if redis.respond_to?(:clear)

    token = MpesaStk::AccessToken.new
    assert_nil token.instance_variable_get(:@token)
  end

  def test_class_call_method
    response_body = {
      access_token: "class_token",
      expires_in: "3599"
    }.to_json

    stub_request(:get, @token_url)
      .with(headers: { "Authorization" => /^Basic / })
      .to_return(status: 200, body: response_body)

    token = MpesaStk::AccessToken.call
    refute_nil token
  end

  def test_class_call_method_with_credentials
    response_body = {
      access_token: "custom_token",
      expires_in: "3599"
    }.to_json

    stub_request(:get, @token_url)
      .with(headers: { "Authorization" => /^Basic / })
      .to_return(status: 200, body: response_body)

    token = MpesaStk::AccessToken.call("custom_key", "custom_secret")
    refute_nil token
  end

  def test_encode_credentials
    token = MpesaStk::AccessToken.new
    encoded = token.send(:encode_credentials, "test_key", "test_secret")
    
    decoded = Base64.decode64(encoded)
    assert_equal "test_key:test_secret", decoded
  end
end

