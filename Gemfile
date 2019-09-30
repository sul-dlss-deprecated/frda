source 'https://rubygems.org'

gem 'bundler', '>= 1.2.0'

gem 'rails', '~> 4'

gem 'google-analytics-rails'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem "blacklight", '~> 4'
#gem 'eadsax', :git => "https://github.com/sul-dlss/eadsax.git"
gem 'ffi'

gem 'faraday'
gem 'scrub_rb'
gem 'rchardet'
gem 'whenever'

gem 'blacklight_dates2svg', '~> 0.0.1.beta5'

gem 'okcomputer'

gem "coderay"
gem 'kaminari', '<= 0.14.1'
gem 'stanford-mods'
gem 'mods_display'
gem 'bootstrap-datepicker-rails'
gem 'net-ssh'

gem 'protected_attributes' # allows use of attr_accessible in models in rails 4

gem 'sass-rails',   '~> 4'
gem 'coffee-rails', '~> 4'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', :platforms => :ruby

gem 'uglifier', '>= 1.0.3'

group :development,:test do
  gem 'rspec-rails', ">=2.14"
  gem 'capybara', '~> 3.15.0' # pinned for ruby 2.3 compatibility
	gem 'launchy'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'test-unit'
end

group :development, :staging, :test do
  gem 'solr_wrapper', '~> 2.0'
  gem 'sqlite3', '~> 1.3.13'
  gem 'quiet_assets'
end

group :staging, :production do
  gem 'mysql2', "~> 0.3.10"
  gem 'minitest'
end

gem 'json'

gem 'rest-client'
gem 'geocoder'
gem 'jquery-rails'

gem "bootstrap-sass"

gem 'awesome_nested_set'

gem 'honeybadger', '~> 2.0'

# gems necessary for capistrano deployment
group :deployment do
  gem 'capistrano', "~> 3.0"
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-passenger'
  gem 'dlss-capistrano', '~> 3.0'
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# To use debugger
# gem 'debugger'

gem 'rubyzip', '< 2', require: false
