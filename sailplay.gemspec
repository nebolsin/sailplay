# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sailplay/version'

Gem::Specification.new do |spec|
  spec.name          = 'sailplay'
  spec.version       = Sailplay::VERSION

  spec.authors       = ['Sergey Nebolsin']
  spec.email         = ['nebolsin@gmail.com']

  spec.summary       = %q{Sailplay API client}
  spec.description   = %q{Wrapper for sailplay.ru REST api}
  spec.homepage      = 'https://github.com/nebolsin/sailplay'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 1.8.7'

  spec.add_runtime_dependency 'multi_json'
  spec.add_runtime_dependency 'rest-client'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 2.0'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'coveralls'

end
