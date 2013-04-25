# -*- encoding: utf-8 -*-
require File.expand_path('../lib/omniauth-matrix/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Sen"]
  gem.email         = ["sen9ob@gmail.com"]
  gem.description   = %q{OmniAuth Oauth2 strategy Matrix.}
  gem.summary       = %q{OmniAuth Oauth2 strategy Matrix.}
  gem.homepage      = "https://github.com/Sen/omniauth-matrix"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "omniauth-matrix"
  gem.require_paths = ["lib"]
  gem.version       = Omniauth::Matrix::VERSION

  gem.add_dependency 'omniauth', '~> 1.0'
  gem.add_dependency 'omniauth-oauth2', '~> 1.0'
end
