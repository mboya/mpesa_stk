# MpesaStk

Copyright (c) 2018 mboya

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

---

A comprehensive Ruby gem for integrating with Safaricom's M-Pesa APIs, IoT services, and related payment solutions. This gem provides easy-to-use interfaces for STK Push, B2C, B2B, C2B, transaction queries, standing orders, IoT SIM management, and more.

[![Gem Version](https://badge.fury.io/rb/mpesa_stk.svg)](https://badge.fury.io/rb/mpesa_stk.svg)
![Cop](https://github.com/mboya/mpesa_stk/workflows/Cop/badge.svg?branch=master)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mpesa_stk'
```
and run the `bundle install` command

Or install it yourself as:
```ruby
gem install mpesa_stk
```

# Getting Started

## Prerequisites

**Redis:** This gem has a [Redis](https://redis.io/) dependency, so make sure it's running:
```bash
$ redis-server
```

You can verify Redis is running:
```bash
$ redis-cli ping
# Should return: PONG
```

**Bundler:** Ensure you have a recent version of bundler (2.4+ recommended for Ruby 3.3+):
```bash
$ gem install bundler
$ bundle --version  # Should show 2.4.0 or higher
```

> **Note:** If you see deprecation warnings about `Gem::Platform.match` or `DidYouMean::SPELL_CHECKERS`, update bundler with `gem install bundler`. These warnings come from older bundler versions and don't affect gem functionality.

you need to setup your environment variables, checkout `.sample.env` for the values you need.
or run
```ruby
$ cp .sample.env .env
```
open `.env` on your editor and add the missing variables. See `.sample.env` for all available configuration options.

**Required for STK Push:**
* `key` and `secret` - Consumer key and secret from your [developer account](https://developer.safaricom.co.ke/user/me/apps)
* `business_short_code` and `business_passkey` - Found in [Test Credentials](https://developer.safaricom.co.ke/test_credentials)
* `callback_url` - Your webhook URL for receiving payment confirmations (must be HTTPS and reachable)

**Required for B2C/B2B/Reversal/Transaction Status:**
* `initiator` or `initiator_name` - API user name
* `security_credential` - Encrypted initiator password (use Safaricom's public key)
* `result_url` - Webhook URL for async results
* `queue_timeout_url` - Webhook URL for timeout notifications

**For C2B:**
* `confirmation_url` - URL for payment confirmations

**For IoT APIs:**
* `iot_api_key` - API key for IoT services (default provided for sandbox)
* `vpn_group` - VPN group identifier
* `username` - Username for IoT operations

`Prod:`

when going live there information will be sent to your email.

for `buy_goods` push  `business_short_code` will be equivalent to `store number` and `till_number` will remain as is.

### Testing out the gem in an actual Rails application

To test out the app on an actual rails application, do check out the following link:

https://github.com/mboya/stk

```shell
  https://github.com/mboya/stk
```
#### Sample application
Check out a rails sample application [here](https://github.com/mboya/stk)

### Quick Start Examples

**Single App (using ENV variables):**
```ruby
$ irb
> require 'mpesa_stk'
> MpesaStk::PushPayment.call("500", "254711222333")
```

**Multiple Apps (using hash parameters):**
```ruby
$ irb
> require 'mpesa_stk'
> hash = {
    "key" => "your_key",
    "secret" => "your_secret",
    "business_short_code" => "174379",
    "business_passkey" => "your_passkey",
    "callback_url" => "https://your-app.com/callback",
    "till_number" => "174379"
  }
> MpesaStk::Push.pay_bill("500", "254711222333", hash)      # Pay Bill
> MpesaStk::Push.buy_goods("500", "254711222333", hash)    # Till Number
```

> **Note:** For complete API documentation with all available endpoints, response formats, and detailed examples, see the [API Reference](#api-reference) and [Response Format & Error Handling](#response-format--error-handling) sections below.

### Mpesa Checkout/Express

After initiating an STK Push, the customer will see a payment prompt on their phone. This is the expected output:

![alt tag](./bin/index.jpeg)

### Callback URL Requirements

Before implementing callbacks, note these requirements:
- **HTTPS Required**: All callback URLs must use HTTPS (not HTTP)
- **Publicly Accessible**: Your callback URLs must be reachable from the internet
- **Response Expected**: Your endpoint should return HTTP 200 OK to acknowledge receipt
- **Timeout**: Safaricom expects a response within 30 seconds

## API Reference

### STK Push (Lipa na M-Pesa Online)

Initiates a payment prompt on the customer's phone. The customer receives an STK push notification and can complete the payment by entering their M-Pesa PIN. This is the same technique the mySafaricom App uses for payments.

**Single App (using ENV variables):**
```ruby
result = MpesaStk::PushPayment.call("500", "254712345678")
```

**Multiple Apps (using hash parameters):**
```ruby
hash = {
  "key" => "your_key",
  "secret" => "your_secret",
  "business_short_code" => "174379",
  "business_passkey" => "your_passkey",
  "callback_url" => "https://your-app.com/callback"
}

# Pay Bill
result = MpesaStk::Push.pay_bill("500", "254712345678", hash)

# Buy Goods (Till Number)
hash["till_number"] = "174379"
result = MpesaStk::Push.buy_goods("500", "254712345678", hash)
```

**Query STK Push Status:**

Check the status of an STK Push transaction using the CheckoutRequestID returned from the initial STK Push request.

```ruby
# Using ENV variables
result = MpesaStk::StkPushQuery.query("ws_CO_DMZ_40472724_16062018092359957")

# Using hash parameters
result = MpesaStk::StkPushQuery.query("ws_CO_DMZ_40472724_16062018092359957", {
  "business_short_code" => "174379",
  "business_passkey" => "your_passkey"
})
```

**STK Push Callbacks:**

After the customer enters their PIN on the checkout/express prompt, you will receive a POST request on your `callback_url` with the transaction status.

**Sample Callback Payload:**
```ruby
{
  "Body" => {
    "stkCallback" => {
      "MerchantRequestID" => "3968-94214-1",
      "CheckoutRequestID" => "ws_CO_160620191218268004",
      "ResultCode" => 0,
      "ResultDesc" => "The service request is processed successfully.",
      "CallbackMetadata" => {
        "Item" => [
          {"Name" => "Amount", "Value" => "05"},
          {"Name" => "MpesaReceiptNumber", "Value" => "OFG4Z5EE9Y"},
          {"Name" => "TransactionDate", "Value" => 20190616121848},
          {"Name" => "PhoneNumber", "Value" => 254711222333}
        ]
      }
    }
  }
}
```

**Result Codes:**
- `0` - Success
- `1032` - Request cancelled by user
- `1037` - Timeout waiting for user input
- `2001` - Insufficient balance
- Other codes indicate various error conditions

### Transaction Status Query

Query the status of any M-Pesa transaction using the transaction ID (M-Pesa Receipt Number). Useful for checking if a payment was successful, failed, or is still pending.

```ruby
# Using ENV variables
result = MpesaStk::TransactionStatus.query("OFR4Z5EE9Y")

# Using hash parameters
result = MpesaStk::TransactionStatus.query("OFR4Z5EE9Y", {
  "initiator" => "testapi",
  "security_credential" => "encrypted_credential",
  "result_url" => "https://your-app.com/result",
  "queue_timeout_url" => "https://your-app.com/timeout"
})
```

**Transaction Status Callbacks:**

Transaction status queries send results to `result_url` and `queue_timeout_url`.

**Sample Result Callback Payload:**
```ruby
{
  "Result" => {
    "ResultType" => 0,
    "ResultCode" => 0,
    "ResultDesc" => "The service request is processed successfully.",
    "OriginatorConversationID" => "12345-67890-1",
    "ConversationID" => "AG_20200101_00001234567890",
    "TransactionID" => "LGR123456789",
    "ResultParameters" => {
      "ResultParameter" => [
        {"Key" => "TransactionStatus", "Value" => "Completed"},
        {"Key" => "TransactionAmount", "Value" => "100.00"},
        {"Key" => "TransactionReceipt", "Value" => "LGR123456789"},
        {"Key" => "B2CWorkingAccountAvailableFunds", "Value" => "50000.00"},
        {"Key" => "B2CUtilityAccountAvailableFunds", "Value" => "100000.00"},
        {"Key" => "TransactionCompletedDateTime", "Value" => "01.01.2020 12:00:00"},
        {"Key" => "ReceiverPartyPublicName", "Value" => "254712345678 - John Doe"}
      ]
    }
  }
}
```

### B2C (Business to Customer)

Send money from a business account to a customer's mobile money account. Commonly used for salary payments, refunds, cashback, or any business-to-customer disbursements. The customer receives the money directly in their M-Pesa account.

**Using ENV variables:**
```ruby
# Set ENV variables: initiator_name, security_credential, result_url, queue_timeout_url
result = MpesaStk::B2C.pay("500", "254712345678", {
  "command_id" => "BusinessPayment", # or "SalaryPayment", "PromotionPayment"
  "remarks" => "Payment for services",
  "occasion" => "Optional occasion" # optional
})
```

**Using hash parameters:**
```ruby
result = MpesaStk::B2C.pay("500", "254712345678", {
  "key" => "your_key",
  "secret" => "your_secret",
  "initiator_name" => "testapi",
  "security_credential" => "encrypted_credential",
  "command_id" => "BusinessPayment", # or "SalaryPayment", "PromotionPayment"
  "remarks" => "Payment for services",
  "occasion" => "Optional occasion", # optional
  "result_url" => "https://your-app.com/result",
  "queue_timeout_url" => "https://your-app.com/timeout"
})
```

**B2C Callbacks:**

B2C payments send results to two callback URLs:
- **Result URL** (`result_url`): Receives transaction results (success or failure)
- **Queue Timeout URL** (`queue_timeout_url`): Receives timeout notifications

**Sample Result Callback Payload:**
```ruby
{
  "Result" => {
    "ResultType" => 0,
    "ResultCode" => 0,
    "ResultDesc" => "The service request is processed successfully.",
    "OriginatorConversationID" => "12345-67890-1",
    "ConversationID" => "AG_20200101_00001234567890",
    "TransactionID" => "LGR123456789",
    "ResultParameters" => {
      "ResultParameter" => [
        {"Key" => "TransactionAmount", "Value" => "100.00"},
        {"Key" => "TransactionReceipt", "Value" => "LGR123456789"},
        {"Key" => "B2CRecipientIsRegisteredCustomer", "Value" => "Y"},
        {"Key" => "B2CChargesPaidAccountAvailableFunds", "Value" => "-100.00"},
        {"Key" => "ReceiverPartyPublicName", "Value" => "254712345678 - John Doe"},
        {"Key" => "TransactionCompletedDateTime", "Value" => "01.01.2020 12:00:00"},
        {"Key" => "B2CUtilityAccountAvailableFunds", "Value" => "50000.00"},
        {"Key" => "B2CWorkingAccountAvailableFunds", "Value" => "100000.00"}
      ]
    },
    "ReferenceData" => {
      "ReferenceItem" => [
        {"Key" => "QueueTimeoutURL", "Value" => "https://your-app.com/timeout"}
      ]
    }
  }
}
```

**Result Codes:**
- `0` - Success
- `1` - Insufficient balance
- `2` - Less than minimum transaction value
- `4` - More than maximum transaction value
- `5` - Would exceed daily transfer limit
- `6` - Would exceed minimum balance
- `8` - Customer account not found
- `11` - Timeout

### B2B (Business to Business)

Send money from one business account to another business account. Used for business-to-business payments such as supplier payments, service payments, or inter-business transfers. Supports both PayBill and Till Number recipients.

**Using ENV variables:**
```ruby
# Set ENV variables: initiator, security_credential, result_url, queue_timeout_url
# Pay Bill
result = MpesaStk::B2B.pay("1000", "123456", {
  "command_id" => "BusinessPayBill", # or "BusinessBuyGoods", "DisburseFundsToBusiness"
  "receiver_identifier_type" => "4" # "4" for paybill, "2" for till
})

# Buy Goods
result = MpesaStk::B2B.pay("1000", "987654", {
  "command_id" => "BusinessBuyGoods",
  "receiver_identifier_type" => "2"
})
```

**Using hash parameters:**
```ruby
# Pay Bill
result = MpesaStk::B2B.pay("1000", "123456", {
  "key" => "your_key",
  "secret" => "your_secret",
  "initiator" => "testapi",
  "security_credential" => "encrypted_credential",
  "command_id" => "BusinessPayBill",
  "receiver_identifier_type" => "4",
  "result_url" => "https://your-app.com/result",
  "queue_timeout_url" => "https://your-app.com/timeout"
})

# Buy Goods
result = MpesaStk::B2B.pay("1000", "987654", {
  "key" => "your_key",
  "secret" => "your_secret",
  "initiator" => "testapi",
  "security_credential" => "encrypted_credential",
  "command_id" => "BusinessBuyGoods",
  "receiver_identifier_type" => "2",
  "result_url" => "https://your-app.com/result",
  "queue_timeout_url" => "https://your-app.com/timeout"
})
```

**B2B Callbacks:**

Similar to B2C, B2B payments use `result_url` and `queue_timeout_url` for callbacks.

**Sample Result Callback Payload:**
```ruby
{
  "Result" => {
    "ResultType" => 0,
    "ResultCode" => 0,
    "ResultDesc" => "The service request is processed successfully.",
    "OriginatorConversationID" => "12345-67890-1",
    "ConversationID" => "AG_20200101_00001234567890",
    "TransactionID" => "LGR123456789",
    "ResultParameters" => {
      "ResultParameter" => [
        {"Key" => "TransactionAmount", "Value" => "1000.00"},
        {"Key" => "TransactionReceipt", "Value" => "LGR123456789"},
        {"Key" => "B2BWorkingAccountAvailableFunds", "Value" => "50000.00"},
        {"Key" => "ReceiverPartyPublicName", "Value" => "600000 - Company Name"},
        {"Key" => "TransactionCompletedDateTime", "Value" => "01.01.2020 12:00:00"},
        {"Key" => "B2BUtilityAccountAvailableFunds", "Value" => "100000.00"}
      ]
    }
  }
}
```

### C2B (Customer to Business)

Enable customers to make payments directly to your business account. Customers initiate payments from their phones, and your business receives notifications.

**Register URLs:**

Register confirmation and validation URLs that Safaricom will call when customers make payments to your PayBill or Till Number. This is a one-time setup required before receiving C2B payments.

**Using ENV variables:**
```ruby
# Set ENV variables: confirmation_url
result = MpesaStk::C2B.register_url({
  "validation_url" => "https://your-app.com/validation", # optional
  "response_type" => "Completed" # or "Cancelled"
})
```

**Using hash parameters:**
```ruby
result = MpesaStk::C2B.register_url({
  "key" => "your_key",
  "secret" => "your_secret",
  "short_code" => "174379",
  "confirmation_url" => "https://your-app.com/confirmation",
  "validation_url" => "https://your-app.com/validation", # optional
  "response_type" => "Completed" # or "Cancelled"
})
```

**Simulate Payment (Sandbox only):**

Simulate a customer payment in the sandbox environment. This allows you to test your C2B integration without requiring actual customer payments. Only available in sandbox, not production.

**Using ENV variables:**
```ruby
# Set ENV variables: business_short_code
result = MpesaStk::C2B.simulate("100", "254712345678", {
  "command_id" => "CustomerPayBillOnline", # or "CustomerBuyGoodsOnline"
  "bill_ref_number" => "INV001" # optional
})
```

**Using hash parameters:**
```ruby
result = MpesaStk::C2B.simulate("100", "254712345678", {
  "key" => "your_key",
  "secret" => "your_secret",
  "short_code" => "174379",
  "command_id" => "CustomerPayBillOnline", # or "CustomerBuyGoodsOnline"
  "bill_ref_number" => "INV001" # optional
})
```

**C2B Callbacks:**

C2B payments use two types of callbacks:
- **Validation URL**: Called when a payment is initiated (you can accept or reject)
- **Confirmation URL** (`confirmation_url`): Called when payment is completed

**Sample Validation Callback Payload:**
```ruby
{
  "TransactionType" => "Pay Bill",
  "TransID" => "LGR123456789",
  "TransTime" => "20200101120000",
  "TransAmount" => "100.00",
  "BusinessShortCode" => "600000",
  "BillRefNumber" => "Invoice123",
  "InvoiceNumber" => "",
  "OrgAccountBalance" => "50000.00",
  "ThirdPartyTransID" => "",
  "MSISDN" => "254712345678",
  "FirstName" => "John",
  "MiddleName" => "",
  "LastName" => "Doe"
}
```

**Sample Confirmation Callback Payload:**
```ruby
{
  "TransactionType" => "Pay Bill",
  "TransID" => "LGR123456789",
  "TransTime" => "20200101120000",
  "TransAmount" => "100.00",
  "BusinessShortCode" => "600000",
  "BillRefNumber" => "Invoice123",
  "InvoiceNumber" => "",
  "OrgAccountBalance" => "50000.00",
  "ThirdPartyTransID" => "",
  "MSISDN" => "254712345678",
  "FirstName" => "John",
  "MiddleName" => "",
  "LastName" => "Doe"
}
```

**Validation Response**: Your validation endpoint should return:
```ruby
{
  "ResultCode" => 0,  # 0 = Accept, C2B00011 = Reject
  "ResultDesc" => "Accepted"
}
```

### Account Balance

Query the current balance of your business M-Pesa account (PayBill or Till Number). Returns the available balance and other account details. Results are sent asynchronously to your ResultURL.

**Using ENV variables:**
```ruby
# Set ENV variables: initiator, security_credential, result_url, queue_timeout_url
result = MpesaStk::AccountBalance.query({})
```

**Using hash parameters:**
```ruby
result = MpesaStk::AccountBalance.query({
  "key" => "your_key",
  "secret" => "your_secret",
  "initiator" => "testapi",
  "security_credential" => "encrypted_credential",
  "party_a" => "174379", # optional, defaults to business_short_code
  "result_url" => "https://your-app.com/result",
  "queue_timeout_url" => "https://your-app.com/timeout"
})
```

**Account Balance Callbacks:**

Account balance queries send results to `result_url` and `queue_timeout_url`.

**Sample Result Callback Payload:**
```ruby
{
  "Result" => {
    "ResultType" => 0,
    "ResultCode" => 0,
    "ResultDesc" => "The service request is processed successfully.",
    "OriginatorConversationID" => "12345-67890-1",
    "ConversationID" => "AG_20200101_00001234567890",
    "ResultParameters" => {
      "ResultParameter" => [
        {"Key" => "AccountBalance", "Value" => "Working Account|KES|50000.00|50000.00|0.00|0.00"},
        {"Key" => "BOCompletedTime", "Value" => "20200101120000"}
      ]
    }
  }
}
```

### Reversal

Reverse a previously completed M-Pesa transaction. Useful for refunds, correcting errors, or handling disputes. The reversal amount must match the original transaction amount. Results are sent asynchronously to your ResultURL.

**Using ENV variables:**
```ruby
# Set ENV variables: initiator, security_credential, result_url, queue_timeout_url
result = MpesaStk::Reversal.reverse("OFR4Z5EE9Y", "100", {})
```

**Using hash parameters:**
```ruby
result = MpesaStk::Reversal.reverse("OFR4Z5EE9Y", "100", {
  "key" => "your_key",
  "secret" => "your_secret",
  "initiator" => "testapi",
  "security_credential" => "encrypted_credential",
  "receiver_party" => "174379", # optional, defaults to business_short_code
  "receiver_identifier_type" => "4", # optional, defaults to "4"
  "result_url" => "https://your-app.com/result",
  "queue_timeout_url" => "https://your-app.com/timeout"
})
```

**Reversal Callbacks:**

Reversal requests send results to `result_url` and `queue_timeout_url`.

**Sample Result Callback Payload:**
```ruby
{
  "Result" => {
    "ResultType" => 0,
    "ResultCode" => 0,
    "ResultDesc" => "The service request is processed successfully.",
    "OriginatorConversationID" => "12345-67890-1",
    "ConversationID" => "AG_20200101_00001234567890",
    "TransactionID" => "LGR123456789",
    "ResultParameters" => {
      "ResultParameter" => [
        {"Key" => "TransactionAmount", "Value" => "100.00"},
        {"Key" => "TransactionReceipt", "Value" => "LGR123456789"},
        {"Key" => "B2CWorkingAccountAvailableFunds", "Value" => "50000.00"},
        {"Key" => "B2CUtilityAccountAvailableFunds", "Value" => "100000.00"},
        {"Key" => "TransactionCompletedDateTime", "Value" => "01.01.2020 12:00:00"}
      ]
    }
  }
}
```

### M-Pesa Ratiba (Standing Orders)

Create standing orders (recurring payments) that automatically charge customers at specified intervals. Perfect for subscriptions, monthly fees, or any recurring billing. Customers authorize the standing order once, and payments are automatically processed according to the frequency you set (daily, weekly, monthly, etc.).

**Using ENV variables:**
```ruby
# Set ENV variables: business_short_code, callback_url
# Monthly subscription (Pay Bill)
result = MpesaStk::Ratiba.create_standing_order({
  "standing_order_name" => "Monthly Subscription",
  "amount" => "500",
  "party_a" => "254712345678",
  "frequency" => "3", # 1=Daily, 2=Weekly, 3=Monthly, 4=Bi-Monthly, 5=Quarterly, 6=Half-Year, 7=Yearly
  "start_date" => "2025-09-25",
  "end_date" => "2026-09-25",
  "account_reference" => "SUB001",
  "transaction_desc" => "Monthly subscription payment"
})

# For Buy Goods (Till Number)
result = MpesaStk::Ratiba.create_standing_order({
  "amount" => "500",
  "party_a" => "254712345678",
  "transaction_type" => "Standing Order Customer Pay Merchant",
  "receiver_party_identifier_type" => "2", # "2" for till number
  "frequency" => "3",
  "start_date" => "2025-09-25",
  "end_date" => "2026-09-25"
})
```

**Using hash parameters:**
```ruby
# Monthly subscription (Pay Bill)
result = MpesaStk::Ratiba.create_standing_order({
  "key" => "your_key",
  "secret" => "your_secret",
  "business_short_code" => "174379",
  "standing_order_name" => "Monthly Subscription",
  "amount" => "500",
  "party_a" => "254712345678",
  "frequency" => "3",
  "start_date" => "2025-09-25",
  "end_date" => "2026-09-25",
  "account_reference" => "SUB001",
  "transaction_desc" => "Monthly subscription payment",
  "callback_url" => "https://your-app.com/callback"
})

# For Buy Goods (Till Number)
result = MpesaStk::Ratiba.create_standing_order({
  "key" => "your_key",
  "secret" => "your_secret",
  "business_short_code" => "300584",
  "amount" => "500",
  "party_a" => "254712345678",
  "transaction_type" => "Standing Order Customer Pay Merchant",
  "receiver_party_identifier_type" => "2",
  "frequency" => "3",
  "start_date" => "2025-09-25",
  "end_date" => "2026-09-25",
  "callback_url" => "https://your-app.com/callback"
})
```

**Note:** Ratiba (Standing Orders) uses the same callback structure as STK Push. When a standing order payment is processed, you'll receive a callback on your `callback_url` with the transaction status.

### IoT APIs

Manage IoT SIM cards and send/receive messages for IoT devices. These APIs allow you to monitor, activate, and manage SIM cards used in IoT deployments, as well as send and receive SMS messages from IoT devices.

**SIM Operations:**

Manage and query information about IoT SIM cards including activation status, lifecycle, customer information, location, and subscription management.

**Using ENV variables:**
```ruby
# Set ENV variables: iot_api_key, vpn_group, username
iot = MpesaStk::IoT.sims({})

# Get all SIMs
result = iot.get_all_sims(start_at_index: 0, page_size: 10)

# Query lifecycle status
result = iot.query_lifecycle_status("0110100606")

# Query customer info
result = iot.query_customer_info("0110100606")

# Activate SIM
result = iot.sim_activation("0110100606")

# Get activation trends
result = iot.get_activation_trends(start_date: "2025-01-01", stop_date: "2025-12-31")

# Rename asset
result = iot.rename_asset("0110100606", "New Asset Name")

# Get location info
result = iot.get_location_info("0110100606")

# Suspend/Unsuspend subscription
result = iot.suspend_unsuspend_sub("0110100606", "product_name", "suspend") # or "unsuspend"
```

**Using hash parameters:**
```ruby
iot = MpesaStk::IoT.sims({
  "key" => "your_key",
  "secret" => "your_secret",
  "iot_api_key" => "Yl4S3KEcr173mbeUdYdjf147IuG3rJ824ArMkP6Z",
  "vpn_group" => "your_vpn_group",
  "username" => "your_username"
})

# All operations work the same way
result = iot.get_all_sims(start_at_index: 0, page_size: 10)
result = iot.query_lifecycle_status("0110100606")
# ... etc
```

**Messaging Operations:**

Send and manage SMS messages to/from IoT devices. Includes functionality to send messages, search message history, filter messages by date/status, and manage message threads.

**Using ENV variables:**
```ruby
# Set ENV variables: iot_api_key, vpn_group, username
messaging = MpesaStk::IoT.messaging({})

# Get all messages
result = messaging.get_all_messages(page_no: 1, page_size: 10)

# Search messages
result = messaging.search_messages("search_term", page_no: 1, page_size: 5)

# Filter messages
result = messaging.filter_messages(
  start_date: "2025-01-01",
  end_date: "2025-12-31",
  status: "sent", # optional
  page_no: 1,
  page_size: 10
)

# Send single message
result = messaging.send_single_message("0110100606", "Hello from API")

# Delete message
result = messaging.delete_message(123)

# Delete message thread
result = messaging.delete_message_thread("0110100606")
```

**Using hash parameters:**
```ruby
messaging = MpesaStk::IoT.messaging({
  "key" => "your_key",
  "secret" => "your_secret",
  "iot_api_key" => "Yl4S3KEcr173mbeUdYdjf147IuG3rJ824ArMkP6Z",
  "vpn_group" => "your_vpn_group",
  "username" => "your_username"
})

# All operations work the same way
result = messaging.get_all_messages(page_no: 1, page_size: 10)
result = messaging.send_single_message("0110100606", "Hello from API")
# ... etc
```

### IMSI/SWAP Operations

Query International Mobile Subscriber Identity (IMSI) and SIM Swap information for a phone number. Useful for fraud prevention, verifying SIM card authenticity, and checking if a SIM card has been swapped recently. Available in both v1 and v2 API versions.

**Using ENV variables:**
```ruby
# Check ATI (v1)
result = MpesaStk::IMSI.check_ati("254712345678", {})

# Check ATI (v2)
result = MpesaStk::IMSI.check_ati("254712345678", {}, version: "v2")
```

**Using hash parameters:**
```ruby
# Check ATI (v1)
result = MpesaStk::IMSI.check_ati("254712345678", {
  "key" => "your_key",
  "secret" => "your_secret"
})

# Check ATI (v2)
result = MpesaStk::IMSI.check_ati("254712345678", {
  "key" => "your_key",
  "secret" => "your_secret"
}, version: "v2")
```

### Pull Transactions

Retrieve historical transaction data from your PayBill or Till Number. This API allows you to pull transaction records for reconciliation, reporting, or analysis purposes.

**Register Pull URL:**

Register a callback URL where Safaricom will send transaction data when you query for transactions. This is a one-time setup required before querying transactions.

**Using ENV variables:**
```ruby
# Set ENV variables: callback_url
result = MpesaStk::PullTransactions.register({
  "request_type" => "pull",
  "nominated_number" => "254712345678"
})
```

**Using hash parameters:**
```ruby
result = MpesaStk::PullTransactions.register({
  "key" => "your_key",
  "secret" => "your_secret",
  "short_code" => "174379",
  "request_type" => "pull",
  "nominated_number" => "254712345678",
  "callback_url" => "https://your-app.com/pull_callback"
})
```

**Query Transactions:**

Query and retrieve transaction records for a specific date range. Returns transaction details including amounts, phone numbers, transaction IDs, and timestamps. Results are sent asynchronously to your registered callback URL.

**Using ENV variables:**
```ruby
# Set ENV variables: business_short_code
result = MpesaStk::PullTransactions.query(
  "2020-08-04 8:36:00",
  "2020-08-16 10:10:00",
  {
    "offset_value" => "0" # optional
  }
)
```

**Using hash parameters:**
```ruby
result = MpesaStk::PullTransactions.query(
  "2020-08-04 8:36:00",
  "2020-08-16 10:10:00",
  {
    "key" => "your_key",
    "secret" => "your_secret",
    "short_code" => "174379",
    "offset_value" => "0" # optional
  }
)
```

**Pull Transactions Callbacks:**

Pull transaction queries send results to the registered `callback_url`.

**Sample Callback Payload:**
```ruby
{
  "Result" => {
    "ResultType" => 0,
    "ResultCode" => 0,
    "ResultDesc" => "The service request is processed successfully.",
    "OriginatorConversationID" => "12345-67890-1",
    "ConversationID" => "AG_20200101_00001234567890",
    "ResultParameters" => {
      "ResultParameter" => [
        {
          "Key" => "TransactionDetails",
          "Value" => "TransactionID|TransactionTime|Amount|MSISDN|FirstName|MiddleName|LastName|BusinessShortCode|BillRefNumber|InvoiceNumber|ThirdPartyTransID|TransactionStatus|TransactionType|OrgAccountBalance"
        }
      ]
    }
  }
}
```

## Handling Callbacks in Your Application

**Rails Example:**
```ruby
# config/routes.rb
post '/mpesa/callback', to: 'mpesa#stk_callback'
post '/mpesa/result', to: 'mpesa#result_callback'
post '/mpesa/timeout', to: 'mpesa#timeout_callback'
post '/mpesa/confirmation', to: 'mpesa#c2b_confirmation'

# app/controllers/mpesa_controller.rb
class MpesaController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:stk_callback, :result_callback, :timeout_callback, :c2b_confirmation]

  def stk_callback
    callback_data = JSON.parse(request.body.read)
    result_code = callback_data.dig('Body', 'stkCallback', 'ResultCode')
    
    if result_code == 0
      # Transaction successful
      metadata = callback_data.dig('Body', 'stkCallback', 'CallbackMetadata', 'Item')
      amount = metadata.find { |item| item['Name'] == 'Amount' }['Value']
      receipt = metadata.find { |item| item['Name'] == 'MpesaReceiptNumber' }['Value']
      # Process successful payment
    else
      # Transaction failed
      result_desc = callback_data.dig('Body', 'stkCallback', 'ResultDesc')
      # Handle failure
    end
    
    render json: { status: 'received' }, status: :ok
  end

  def result_callback
    result_data = JSON.parse(request.body.read)
    result_code = result_data.dig('Result', 'ResultCode')
    
    if result_code == 0
      # Process successful result
    else
      # Handle error
    end
    
    render json: { status: 'received' }, status: :ok
  end

  def timeout_callback
    timeout_data = JSON.parse(request.body.read)
    # Handle timeout
    render json: { status: 'received' }, status: :ok
  end

  def c2b_confirmation
    confirmation_data = JSON.parse(request.body.read)
    trans_id = confirmation_data['TransID']
    amount = confirmation_data['TransAmount']
    # Process C2B payment confirmation
    render json: { status: 'received' }, status: :ok
  end
end
```

**Sinatra Example:**
```ruby
require 'sinatra'
require 'json'

post '/mpesa/callback' do
  callback_data = JSON.parse(request.body.read)
  # Process callback
  status 200
  { status: 'received' }.to_json
end
```

**Best Practices:**

1. **Always Return 200 OK**: Your callback endpoint must return HTTP 200 OK within 30 seconds
2. **Idempotency**: Use `TransactionID` or `CheckoutRequestID` to prevent duplicate processing
3. **Logging**: Log all callbacks for debugging and audit purposes
4. **Error Handling**: Handle network issues and retries gracefully
5. **Security**: Validate callback authenticity (consider IP whitelisting or signature verification)
6. **Queue Processing**: Use background jobs for processing callbacks to avoid timeouts

## Response Format & Error Handling

### Success Response Format

All API methods return a hash with the response. Success responses typically include:
- `ResponseCode`: "0" indicates success
- `ResponseDescription`: Human-readable description
- `MerchantRequestID` / `OriginatorConversationID`: Request identifiers
- `CheckoutRequestID` / `ConversationID`: Transaction identifiers

**Example Success Response:**
```ruby
{
  "MerchantRequestID" => "7909-1302368-1",
  "CheckoutRequestID" => "ws_CO_DMZ_40472724_16062018092359957",
  "ResponseCode" => "0",
  "ResponseDescription" => "Success. Request accepted for processing",
  "CustomerMessage" => "Success. Request accepted for processing"
}
```

### Error Response Format

Error responses include:
- `errorCode`: Error code (e.g., "500.001.1001")
- `errorMessage`: Error description
- `requestId`: Request identifier

**Example Error Response:**
```ruby
{
  "requestId" => "13022-8633727-1",
  "errorCode" => "500.001.1001",
  "errorMessage" => "Error Message"
}
```

### Error Handling

All methods raise `StandardError` with descriptive messages when:
- HTTP requests fail
- Required configuration is missing
- API returns error responses

```ruby
begin
  result = MpesaStk::PushPayment.call("500", "254712345678")
rescue StandardError => e
  puts "Error: #{e.message}"
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run the tests:

```bash
# Run all tests
ruby -Itest test/*_test.rb

# Or run specific test file
ruby -Itest test/access_token_test.rb
```

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

**Note:** If you encounter bundler deprecation warnings, update bundler with `gem install bundler` (requires bundler 2.4+ for Ruby 3.3+).

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mboya/mpesa_stk.

To Contribute to this gem,
* Comment on the issue you would like to work on solving.
* Mark the issue as in progress by adding an `in-progress` label.
* Fork the project to your github repository (This project only accepts PRs from forks)
* Submit the PR after the implementation all unfinished PRs for an issue should have a WIP indicated beside it
* Every PR should have a link to the issue being solved
* Checkout this [github best practices](https://github.com/skyscreamer/yoga/wiki/GitHub-Best-Practices) for more info.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the MpesaStk project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/mboya/mpesa_stk/blob/master/CODE_OF_CONDUCT.md).

