# coding: utf-8

Gem::Specification.new do |s|
  s.name        = 'selwet'
  s.version     = '0.0.1'
  s.summary     = "Selenium Web Test"
  s.authors     = ["Motin Artem"]
  s.email       = 'a.motin@inventos.ru'
  s.files       = ["lib/selwet.rb"]
  s.license       = 'MIT'
  s.require_paths = ["lib"]
  s.add_development_dependency "selenium-webdriver", '~> 2.44'
  s.add_development_dependency "test-unit", '~> 3.0', '>= 3.0.6'
  s.add_development_dependency "shoulda-context", '~> 1.2', '>= 1.2.1'
  s.add_development_dependency "bundler", "~> 1.6"
end