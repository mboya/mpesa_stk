# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-01-XX

### Added

#### New API Endpoints

- **Transaction Status Query** (`MpesaStk::TransactionStatus`)
  - Query the status of any M-Pesa transaction
  - Supports querying by transaction ID
  - Full error handling and response parsing

- **STK Push Query** (`MpesaStk::StkPushQuery`)
  - Query the status of STK Push transactions
  - Check payment request status using CheckoutRequestID

- **Business to Customer (B2C)** (`MpesaStk::B2C`)
  - Send money from business to customer
  - Supports salary payments, promotions, and other B2C transactions
  - Configurable command IDs and remarks

- **Business to Business (B2B)** (`MpesaStk::B2B`)
  - Send money from business to business
  - Supports PayBill to PayBill and PayBill to Buy Goods transactions
  - Full support for sender and receiver account references

- **Customer to Business (C2B)** (`MpesaStk::C2B`)
  - Register C2B validation and confirmation URLs
  - Simulate C2B payments for testing
  - Complete C2B payment flow support

- **Account Balance Query** (`MpesaStk::AccountBalance`)
  - Query account balance for PayBill or Till Number
  - Supports both Initiator and PartyA queries

- **Transaction Reversal** (`MpesaStk::Reversal`)
  - Reverse M-Pesa transactions
  - Supports full and partial reversals
  - Configurable timeout and result URLs

- **M-Pesa Ratiba (Standing Orders)** (`MpesaStk::Ratiba`)
  - Create recurring payment standing orders
  - Schedule automatic payments
  - Manage subscription-based payments

- **IoT SIM Management & Messaging** (`MpesaStk::IoT`)
  - **SIM Operations:**
    - Get all SIMs with pagination
    - Query lifecycle status
    - Query customer information
    - SIM activation
    - Get activation trends
    - Rename assets
    - Get location information
    - Suspend/unsuspend subscriptions
  - **Messaging Operations:**
    - Get all messages with pagination
    - Search messages
    - Filter messages by date/status
    - Send single messages to IoT devices
    - Delete messages and message threads

- **IMSI/SWAP Operations** (`MpesaStk::IMSI`)
  - Check ATI (Access Transaction Information)
  - Query IMSI and SIM swap information
  - Supports both v1 and v2 API versions
  - Useful for fraud prevention and SIM verification

- **Pull Transactions** (`MpesaStk::PullTransactions`)
  - Register pull transaction callback URLs
  - Query historical transactions
  - Retrieve transaction data for reconciliation

#### Testing Infrastructure

- Comprehensive test suite with 148 tests covering all features
- Test files for all new API endpoints:
  - `test/transaction_status_test.rb`
  - `test/stk_push_query_test.rb`
  - `test/b2c_test.rb`
  - `test/b2b_test.rb`
  - `test/c2b_test.rb`
  - `test/account_balance_test.rb`
  - `test/reversal_test.rb`
  - `test/ratiba_test.rb`
  - `test/iot_test.rb`
  - `test/imsi_test.rb`
  - `test/pull_transactions_test.rb`
- Enhanced `MockRedis` class for isolated testing without external Redis dependency
- Improved test helper with comprehensive environment variable setup
- All tests use WebMock for HTTP request stubbing

#### Documentation

- Comprehensive README.md update with:
  - Detailed API reference for all endpoints
  - Usage examples using both ENV variables and hash parameters
  - Descriptions for each API endpoint explaining their purpose
  - Consolidated response format and error handling sections
  - Quick start examples
  - Complete configuration guide
- Updated `.sample.env` with all new environment variables
- Clear documentation of required vs optional parameters

#### Configuration

- Added support for hash-based parameter passing for all APIs
- Enhanced ENV variable support for all new endpoints
- Improved error messages for missing configuration
- Standardized configuration access across all classes

### Changed

#### Dependencies

- Added explicit `base64` dependency (>= 0.1.0) for Ruby 3.4+ compatibility
- Added explicit `csv` dependency (>= 3.0.0) for Ruby 3.4+ compatibility
- Updated `minitest` to ~> 5.20 for Ruby 3.3+ compatibility
- Updated `pry` to ~> 0.12 for compatibility
- Updated `pry-nav` to ~> 0.3 for compatibility
- Updated `httparty` constraint to < 0.22.0
- All dependencies now compatible with Ruby 3.3+

#### Code Quality

- Improved error handling across all API classes
- Standardized error messages and exception types
- Enhanced HTTP response validation
- Better handling of missing configuration
- Improved code consistency across all classes
- Added `frozen_string_literal: true` to gemspec

#### Test Infrastructure

- Fixed circular require warnings in Ruby 3.3+
- Improved test isolation with better MockRedis implementation
- Enhanced test helper with proper warning suppression
- Better test organization and structure

#### CI/CD

- Updated GitHub Actions workflow:
  - Updated `actions/checkout` to v4
  - Updated Ruby setup action to `ruby/setup-ruby@v1`
  - Updated Ruby version to 3.1
  - Added `bundler-cache: true` for faster builds
  - Added `pull_request` trigger

### Fixed

- Fixed Ruby 3.4+ compatibility warnings for `base64` and `csv` gems
- Fixed circular require warnings in test suite (Ruby 3.3+)
- Fixed `MockRedis` shared storage issue in tests
- Fixed assertion method names in tests (`assert_not_equal` → `refute_equal`)
- Fixed syntax error in `MpesaStk::IMSI` class
- Improved error handling for Redis connection failures
- Fixed generic exception handling (changed to `ArgumentError` where appropriate)

### Improved

- Better separation of concerns across API classes
- More consistent API design patterns
- Enhanced documentation and examples
- Improved code maintainability
- Better error messages for debugging

## [1.3.0] - Previous Version

### Features

- STK Push payment initiation
- Access token management with Redis caching
- Support for multiple applications with custom credentials
- Basic error handling and response parsing

---

## Version History

- **2.0.0** - Major release with comprehensive API coverage, full test suite, and Ruby 3.3+ compatibility
- **1.3.0** - Initial stable release with STK Push functionality

---

## Migration Guide

### Upgrading from 1.3.x to 2.0.0

1. **Update Dependencies:**
   ```bash
   bundle update mpesa_stk
   ```

2. **New Environment Variables:**
   Add the following to your `.env` file (see `.sample.env` for complete list):
   - `transaction_status_url`
   - `stk_push_query_url`
   - `b2c_url`, `b2b_url`
   - `c2b_register_url`, `c2b_simulate_url`
   - `account_balance_url`
   - `reversal_url`
   - `ratiba_url`
   - `iot_base_url`, `iot_api_key`, `vpn_group`, `username`
   - `imsi_v1_url`, `imsi_v2_url`
   - `pull_transactions_register_url`, `pull_transactions_query_url`
   - `initiator`, `initiator_name`, `security_credential`
   - `result_url`, `queue_timeout_url`, `confirmation_url`

3. **Ruby Version:**
   Ensure you're using Ruby 2.6.0 or higher (Ruby 3.3+ recommended)

4. **Redis:**
   Redis 4.0+ is now required

5. **API Changes:**
   - All existing STK Push APIs remain backward compatible
   - New APIs follow consistent patterns with both ENV and hash parameter support
   - Error handling has been improved but maintains backward compatibility

### Breaking Changes

None - This release maintains full backward compatibility with version 1.3.x.

---

## Contributors

- mboya
- cess

---

## Links

- [GitHub Repository](https://github.com/mboya/mpesa_stk)
- [RubyGems](https://rubygems.org/gems/mpesa_stk)
- [Safaricom Developer Portal](https://developer.safaricom.co.ke/)

