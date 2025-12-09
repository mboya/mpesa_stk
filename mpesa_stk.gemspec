# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mpesa_stk/version'

Gem::Specification.new do |spec|
  spec.name          = 'mpesa_stk'
  spec.version       = MpesaStk::VERSION
  spec.authors       = %w[mboya cess]
  spec.email         = ['mboyaberry@gmail.com', 'cessmbuguar@gmail.com']

  spec.summary       = 'Lipa na M-Pesa Online Payment.'
  spec.description   = 'initiate a M-Pesa transaction on behalf of a customer using STK Push.'
  spec.homepage      = 'https://github.com/mboya/mpesa_stk'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.6.0'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = "#{spec.homepage}.git"
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.add_dependency 'base64', '>= 0.1.0'
  spec.add_dependency 'csv', '>= 3.0.0'
  spec.add_dependency 'httparty', '>= 0.15.6', '< 0.22.0'
  spec.add_dependency 'redis', '>= 4.0'
  spec.add_dependency 'redis-namespace', '~> 1.5', '>= 1.5.3'
  spec.add_dependency 'redis-rack', '~> 2.0', '>= 2.0.2'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'minitest', '~> 5.20'
  spec.add_development_dependency 'rake', '>= 12.3.3'

  spec.add_development_dependency 'dotenv', '~> 2.8'
  spec.add_development_dependency 'pry', '~> 0.12'
  spec.add_development_dependency 'pry-nav', '~> 0.3'
  spec.add_development_dependency 'rubocop', '~> 1.0'
  spec.add_development_dependency 'webmock', '~> 3.18'
end
