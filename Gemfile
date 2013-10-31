source 'https://rubygems.org'

gem 'rake'
gem 'rspec'
gem 'jeweler'
gem 'builder'
gem 'sinatra'
gem 'yard'

group :development, :test do
  gem 'rspec-puppet',            :require => false
  gem 'puppetlabs_spec_helper',  :require => false
  gem 'rspec-system-puppet',     :require => false
  gem 'puppet-lint',             :require => false
  gem 'serverspec',              :require => false
  gem 'rspec-system-serverspec', :require => false
  gem 'pry',                     :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end
