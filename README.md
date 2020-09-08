# MpesaStk
Lipa na M-Pesa Online Payment API is used to initiate a M-Pesa transaction on behalf of a customer using STK Push. This is the same technique mySafaricom App uses whenever the app is used to make payments.

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
This gem has a [Redis](https://redis.io/) dependency, so make sure it running
```ruby
$ redis-server
```
You can use command line to determine if redis is running:
```ruby
redis-cli ping
```
you should get back
```ruby
PONG
```

you need to setup your environment variables, checkout `.sample.env` for the values you need.
or run
```ruby
$ cp .sample.env .env
```
open `.env` on your editor and add the missing variable
```
key=""
secret=""
business_short_code=""
business_passkey=""
callback_url=""
till_number=""
```

* `key` and `secret` of the app created on your [developer account](https://developer.safaricom.co.ke/user/me/apps).
* `business_short_code`  and `business_pass_key` this can be found in [Test Credentials](https://developer.safaricom.co.ke/test_credentials).
* `callback_url` the url of your application where response will be sent. `make sure its a reachable/active url`

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

### Testing the gem on the console/app
When running the gem on a single safaricom app.

```ruby
$ irb
2.5.0 :001 > require 'mpesa_stk'
2.5.0 :002 > MpesaStk::PushPayment.call("500", "<YOUR PHONE NUMBER: 254711222333>")
```

When running the app on multiple safaricom apps, within the same project.
```ruby
$ irb
2.5.3 :001 > require 'mpesa_stk'
2.5.3 :002 > hash = Hash.new
2.5.3 :003 > 
2.5.3 :004 > hash['key'] = key
2.5.3 :005 > hash['secret'] = secret
2.5.3 :006 > hash['business_short_code'] = business_short_code
2.5.3 :007 > hash['business_passkey'] = business_passkey
2.5.3 :008 > hash['callback_url'] = callback_url
2.5.3 :009 > hash['till_number'] = till_number 
```
for STK push
```ruby
2.5.3 :010 > MpesaStk::Push.pay_bill('05', "<YOUR PHONE NUMBER: 254711222333>", hash)
```
for Till Number push
```ruby
2.5.3 :010 > MpesaStk::Push.buy_goods('05', "<YOUR PHONE NUMBER: 254711222333>", hash)
```
possible error format if the request is not successful
```hash
{"requestId"=>"13022-8633727-1", "errorCode"=>"500.001.1001", "errorMessage"=>"Error Message"}
```

expected irb output after the command
```hash
  {
    "MerchantRequestID"=>"7909-1302368-1", 
    "CheckoutRequestID"=>"ws_CO_DMZ_40472724_16062018092359957", 
    "ResponseCode"=>"0", 
    "ResponseDescription"=>"Success. Request accepted for processing", 
    "CustomerMessage"=>"Success. Request accepted for processing"
  }
```

the above response means the response has been successfully sent to Safaricom for processing and you should be able to see the checkout/express prompt on the sender number.

### Mpesa Checkout/Express
This is the expected output on the mobile phone

![alt tag](./bin/index.jpeg)

### Callback url

After the pin code is entered on the checkout/express prompt. you will receive a request on the provided  `callback_url` with the status of the action

sample payload that you will be getting on your callback
```hash
{"Body"=>{"stkCallback"=>{"MerchantRequestID"=>"3968-94214-1", "CheckoutRequestID"=>"ws_CO_160620191218268004", "ResultCode"=>0, "ResultDesc"=>"The service request is processed successfully.", 
"CallbackMetadata"=>{"Item"=>[{"Name"=>"Amount", "Value"=>"05"}, {"Name"=>"MpesaReceiptNumber", "Value"=>"OFG4Z5EE9Y"}, {"Name"=>"TransactionDate", "Value"=>20190616121848}, 
{"Name"=>"PhoneNumber", "Value"=>254711222333}]}}}, "push"=>{"Body"=>{"stkCallback"=>{"MerchantRequestID"=>"3968-94214-1", "CheckoutRequestID"=>"ws_CO_160620191218268004", "ResultCode"=>0, 
"ResultDesc"=>"The service request is processed successfully.", "CallbackMetadata"=>{"Item"=>[{"Name"=>"Amount", "Value"=>"05"}, {"Name"=>"MpesaReceiptNumber", "Value"=>"OFG4Z5EE9Y"}, {"Name"=>"TransactionDate", 
"Value"=>20190616121848}, {"Name"=>"PhoneNumber", "Value"=>254711222333}]}}}}}
```

### Query Request
This API allows you to check the status of a Lipa Na M-Pesa Online Payment.

```ruby
$ irb
2.5.3 :001 > require 'mpesa_stk'
2.5.0 :002 > MpesaStk::PushPayment.call("500", "<YOUR PHONE NUMBER: 254711222333>")
```
expected irb output after the command
```hash
  {
    "MerchantRequestID"=>"11112-111619600-1", "CheckoutRequestID"=>"ws_CO_080920202234262864", "ResponseCode"=>"0", "ResponseDescription"=>"Success. Request accepted for processing", "CustomerMessage"=>"Success. Request accepted for processing"
  }
```
Now query the request status, the `MpesaStk::QueryPayment.call()` functionality takes a `CheckoutRequestID` as its only parameter as shown below.
```ruby
2.5.0 :002 > MpesaStk::QueryPayment.call("ws_CO_080920202234262864")
```
expected irb output after the command
```hash
  {
    "ResponseCode"=>"0", "ResponseDescription"=>"The service request has been accepted successsfully", "MerchantRequestID"=>"11112-111619600-1", "CheckoutRequestID"=>"ws_CO_080920202234262864", "ResultCode"=>"0", "ResultDesc"=>"The service request is processed successfully."
  }
```
Incase the user canceled the request you get an output like below:

```hash
  {
    "ResponseCode"=>"0", "ResponseDescription"=>"The service request has been accepted successsfully", "MerchantRequestID"=>"28282-53573408-1", "CheckoutRequestID"=>"ws_CO_080920202236494435", "ResultCode"=>"1032", "ResultDesc"=>"Request cancelled by user"
  }
```





## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

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

