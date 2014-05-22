# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'balanced/spectator/version'
require 'base64'

Gem::Specification.new do |spec|
  spec.name          = "balanced-spectator"
  spec.version       = Balanced::Spectator::VERSION
  spec.authors       = ["Ben Mills"]
  spec.email         = ["YmVuQHVuZmluaXRpLmNvbQ"].map { |i| Base64.decode64(i) }
  spec.summary       = %q{Rack middleware to enqueue Balanced events to RabbitMQ}
  spec.description   = %q{Provides a Rack middleware to listen for Balanced events and enqueue them in RabbitMQ}
  spec.homepage      = %q{https://www.balancedpayments.com}
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  
  spec.add_dependency("json")
  spec.add_dependency("bunny")
end
