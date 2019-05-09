require "test_helper"

class MpesaStkTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::MpesaStk::VERSION
  end

  def test_it_does_something_useful
    assert true
  end

  # def test_can_push_payment
  #   token = "QWJjcjdhRHNPemFQbGY1Q2Q2RldCSnF4aDZ6UkoyZHk6OVVWek9IaERxNDRua1pXUA=="
  #   stub_request(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials").
  #     with(  headers: {
  #       'Authorization'=>"Basic #{token}"
  #       }).to_return(status: 200, body: "", headers: {})

  # 	payment = ::MpesaStk::PushPayment.call('10', '254722111333')
  # end
end
