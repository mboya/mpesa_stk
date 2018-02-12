# MpesaStk
Lipa na M-Pesa Online Payment API is used to initiate a M-Pesa transaction on behalf of a customer using STK Push. This is the same technique mySafaricom App uses whenever the app is used to make payments.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mpesa_stk'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mpesa_stk

## Usage

one needs to setup there environment variables, checkout `.sample.env`
```
base_url="https://sandbox.safaricom.co.ke"
token_generator_url="/oauth/v1/generate?grant_type=client_credentials"
process_request_url="/mpesa/stkpush/v1/processrequest"

key=""
secret=""
business_short_code=""
business_passkey="
callback_url="
```
this can be found in [Test Credentials](https://developer.safaricom.co.ke/test_credentials)

### Implementation

This now becomes the easy part. After all the pieces above have been set all you need to do is:
open your console and add.
```
MpesaStk::PushPayment.call("500", "<YOUR PHONE NUMBER>")
```

### Output

![STK Notification](https://photos.google.com/u/1/share/AF1QipPF8cdssxur1v9Wiatg01Geb4SMf_crfgOb1jC3maEZzjn1F2-5fBQuHKuaK1WDnw/photo/AF1QipMrsrF-mmpPrZtuCVBaOEiWcTdolGVsejIxCZ3e?key=dXMxUmMzQi1vQmNsQjJNMXcxTHBDS19TVjR1NElB)



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/mpesa_stk. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the MpesaStk project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/mpesa_stk/blob/master/CODE_OF_CONDUCT.md).
