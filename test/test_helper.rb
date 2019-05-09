$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "mpesa_stk"
require 'webmock/minitest'

require "minitest/autorun"
Redis.new
WebMock.disable_net_connect!