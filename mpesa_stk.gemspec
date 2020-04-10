
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mpesa_stk/version"

Gem::Specification.new do |spec|
  spec.name          = "mpesa_stk"
  spec.version       = MpesaStk::VERSION
  spec.authors       = ["mboya", "cess"]
  spec.email         = ["mboyaberry@gmail.com", "cessmbuguar@gmail.com"]

  spec.summary       = %q{Lipa na M-Pesa Online Payment.}
  spec.description   = %q{initiate a M-Pesa transaction on behalf of a customer using STK Push.}
  spec.homepage      = "https://github.com/mboya/mpesa_stk"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'httparty', '>= 0.15.6', '< 0.19.0'
  spec.add_dependency 'redis-rack', '~> 2.0', '>= 2.0.2'
  spec.add_dependency 'redis-namespace', '~> 1.5', '>= 1.5.3'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.add_development_dependency 'pry', '~> 0.10.4'
  spec.add_development_dependency 'pry-nav', '~> 0.2.4'
  spec.add_development_dependency 'webmock', '~> 3.0', '>= 3.0.1'
  spec.add_development_dependency "dotenv", "2.7.5"
end
