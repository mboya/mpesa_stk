$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "mpesa_stk"
require 'webmock/minitest'
require "minitest/autorun"
WebMock.disable_net_connect!
$redis = Redis.new
