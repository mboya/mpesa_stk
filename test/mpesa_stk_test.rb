require "test_helper"

class MpesaStkTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::MpesaStk::VERSION
    assert_equal "1.3", ::MpesaStk::VERSION
  end

  def test_module_is_defined
    assert defined?(MpesaStk)
  end

  def test_access_token_class_exists
    assert defined?(MpesaStk::AccessToken)
  end

  def test_push_payment_class_exists
    assert defined?(MpesaStk::PushPayment)
  end

  def test_push_class_exists
    assert defined?(MpesaStk::Push)
  end

  def test_transaction_status_class_exists
    assert defined?(MpesaStk::TransactionStatus)
  end

  def test_stk_push_query_class_exists
    assert defined?(MpesaStk::StkPushQuery)
  end

  def test_b2c_class_exists
    assert defined?(MpesaStk::B2C)
  end

  def test_b2b_class_exists
    assert defined?(MpesaStk::B2B)
  end

  def test_c2b_class_exists
    assert defined?(MpesaStk::C2B)
  end

  def test_account_balance_class_exists
    assert defined?(MpesaStk::AccountBalance)
  end

  def test_reversal_class_exists
    assert defined?(MpesaStk::Reversal)
  end

  def test_ratiba_class_exists
    assert defined?(MpesaStk::Ratiba)
  end

  def test_iot_class_exists
    assert defined?(MpesaStk::IoT)
  end

  def test_imsi_class_exists
    assert defined?(MpesaStk::IMSI)
  end

  def test_pull_transactions_class_exists
    assert defined?(MpesaStk::PullTransactions)
  end
end

