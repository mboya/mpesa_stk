$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Suppress circular require warnings from Ruby 3.3+ bundled_gems.rb
# This is a known issue with minitest/webmock interaction and is harmless
# We only suppress warnings during the problematic requires
begin
  original_verbose = $VERBOSE
  $VERBOSE = nil
  require "minitest/autorun"
  require "webmock/minitest"
ensure
  $VERBOSE = original_verbose
end

require "mpesa_stk"

# Setup test environment variables
ENV["base_url"] ||= "https://sandbox.safaricom.co.ke"
ENV["token_generator_url"] ||= "/oauth/v1/generate?grant_type=client_credentials"
ENV["process_request_url"] ||= "/mpesa/stkpush/v1/processrequest"
ENV["key"] ||= "test_key"
ENV["secret"] ||= "test_secret"
ENV["business_short_code"] ||= "174379"
ENV["business_passkey"] ||= "test_passkey"
ENV["callback_url"] ||= "https://api.endpoint/callback"
ENV["till_number"] ||= "174379"
ENV["transaction_status_url"] ||= "/mpesa/transactionstatus/v1/query"
ENV["stk_push_query_url"] ||= "/mpesa/stkpushquery/v1/query"
ENV["b2c_url"] ||= "/mpesa/b2c/v1/paymentrequest"
ENV["b2b_url"] ||= "/mpesa/b2b/v1/paymentrequest"
ENV["c2b_register_url"] ||= "/mpesa/c2b/v1/registerurl"
ENV["c2b_simulate_url"] ||= "/mpesa/c2b/v1/simulate"
ENV["account_balance_url"] ||= "/mpesa/accountbalance/v1/query"
ENV["reversal_url"] ||= "/mpesa/reversal/v1/request"
ENV["ratiba_url"] ||= "/standingorder/v1/createStandingOrderExternal"
ENV["iot_base_url"] ||= "/simportal/v1"
ENV["pull_transactions_register_url"] ||= "/pulltransactions/v1/register"
ENV["pull_transactions_query_url"] ||= "/pulltransactions/v1/query"
ENV["initiator"] ||= "testapi"
ENV["initiator_name"] ||= "testapi"
ENV["security_credential"] ||= "encrypted_security_credential"
ENV["result_url"] ||= "https://api.endpoint/result"
ENV["queue_timeout_url"] ||= "https://api.endpoint/queue_timeout"
ENV["confirmation_url"] ||= "https://api.endpoint/confirmation"
ENV["iot_api_key"] ||= "Yl4S3KEcr173mbeUdYdjf147IuG3rJ824ArMkP6Z"
ENV["vpn_group"] ||= ""
ENV["username"] ||= ""

# Mock Redis for testing
require "redis"
class MockRedis
  @@data = {}

  def initialize(*args)
    # Use class variable to share data across instances
  end

  def get(key)
    @@data[key]
  end

  def set(key, value)
    @@data[key] = value
  end

  def clear
    @@data.clear
  end

  def self.clear_all
    @@data.clear
  end
end

# Replace Redis.new with MockRedis for tests
Redis.define_singleton_method(:new) do |*args|
  MockRedis.new(*args)
end

WebMock.disable_net_connect!