require "test_helper"
require "redis"

class MpesaStkTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::MpesaStk::VERSION
  end

  def test_it_does_something_useful
    assert true
  end

  def test_cannot_make_an_external_request
    stub = stub_request(:get, "https://rubygems.org/gems/mpesa_stk").
        with(
            headers: {
                'Accept' => '*/*',
                'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'User-Agent' => 'Ruby'
            }).
        to_return(status: 200, body: "", headers: {})
    assert_not_requested stub
  end

  def test_can_fetch_token
    $redis.flushall
    ENV['base_url'] = "https://sandbox"
    ENV['token_generator_url'] = "token/generate"
    stub = stub_request(:get, "#{ENV['base_url']}#{ENV['token_generator_url']}").
        to_return(status: 200, body: {'access_token' => 'QWJjcjdhRHNPemFQbGY1Q2Q2RldCSnF4aDZ6UkoyZHk6OVVWek9IaERxNDRua1pXUA==', 'expires_in' => '3599'}.to_json, headers: {})

    token = MpesaStk::AccessToken.call
    assert_requested stub
  end

  # def test_can_push_stk
  #   $redis.flushall
  #   ENV['base_url'] = "https://sandbox"
  #   ENV['token_generator_url'] = "token/generate"
  #   ENV['process_request_url'] = "/stkpush"
  #   ENV['business_short_code']=""
  #   ENV['business_passkey']=""
  #
  #   key = "#{ENV['business_short_code']}#{ENV['business_passkey']}#{DateTime.now.strftime("%Y%m%d%H%M%S").to_i}"
  #   password = Base64.encode64(key).split("\n").join
  #
  #   token_stub = stub_request(:get, "#{ENV['base_url']}#{ENV['token_generator_url']}").
  #       to_return(status: 200, body: {'access_token' => 'QWJjcjdhRHNPemFQbGY1Q2Q2RldCSnF4aDZ6UkoyZHk6OVVWek9IaERxNDRua1pXUA==', 'expires_in' => '3599'}.to_json, headers: {})
  #   stk_push_stub = stub_request(:post, "#{ENV['base_url']}#{ENV['process_request_url']}").
  #       with(
  #           body: "{\"BusinessShortCode\":\"\",\"Password\":\"#{password}=\",\"Timestamp\":\"20200502202935\",\"TransactionType\":\"CustomerPayBillOnline\",\"Amount\":\"10\",\"PartyA\":\"254722111333\",\"PartyB\":\"\",\"PhoneNumber\":\"254722111333\",\"CallBackURL\":\"\",\"AccountReference\":\"zooTu\",\"TransactionDesc\":\"hSMWM\"}",
  #           headers: {
  #               'Accept' => '*/*',
  #               'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
  #               'Authorization' => 'Bearer QWJjcjdhRHNPemFQbGY1Q2Q2RldCSnF4aDZ6UkoyZHk6OVVWek9IaERxNDRua1pXUA==',
  #               'Content-Type' => 'application/json',
  #               'User-Agent' => 'Ruby'
  #           }).
  #       to_return(status: 200, body: "", headers: {})
  #
  #   payment = ::MpesaStk::PushPayment.call('10', '254722111333')
  #
  #   assert_requested token_stub
  #   assert_requested stk_push_stub
  # end

  # def test_can_push_payment
  #   token = "QWJjcjdhRHNPemFQbGY1Q2Q2RldCSnF4aDZ6UkoyZHk6OVVWek9IaERxNDRua1pXUA=="
  #   stub_request(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials").
  #     with(  headers: {
  #       'Authorization'=>"Basic #{token}"
  #       }).to_return(status: 200, body: "", headers: {})
  #
  # # 	payment = ::MpesaStk::PushPayment.call('10', '254722111333')
  # end
end
