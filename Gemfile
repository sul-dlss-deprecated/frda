source 'https://rubygems.org'

gem 'bundler', '>= 1.2.0'

gem 'rails', '~> 3.2.22'

gem 'google-analytics-rails'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem "blacklight", '~> 4.7.0'
#gem 'eadsax', :git => "https://github.com/sul-dlss/eadsax.git"
gem 'ffi'

gem 'faraday'
gem 'scrub_rb'
gem 'rchardet'

gem 'blacklight_dates2svg', '~> 0.0.1.beta3'

gem "coderay"
gem 'kaminari', '<= 0.14.1'
gem 'stanford-mods'
gem 'mods_display'
gem 'bootstrap-datepicker-rails'
gem 'net-ssh', '< 3' # net-ssh 2 needed for ruby 1.9 compatibility
# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

group :development,:test do
  gem 'rspec-rails', ">=2.14"
  gem 'capybara'
	gem 'launchy'
  gem 'better_errors', "< 2.0" # v2.0 or greater does not support Ruby 1.9 anymore, which is what is currently running in FRDA prod
  gem 'binding_of_caller', "~> 0.7"
  gem 'meta_request'
  gem 'test-unit'
end

group :development, :staging, :test do
  gem 'jettywrapper'
  gem 'sqlite3'
end

group :staging, :production do
  gem 'mysql2', "~> 0.3.10"
end

gem 'json'

gem 'rest-client'
gem 'geocoder'
gem 'jquery-rails'

gem "bootstrap-sass"

gem 'awesome_nested_set'

# gems necessary for capistrano deployment
group :deployment do
  gem 'capistrano', "~> 3.0"
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-passenger'
  gem 'lyberteam-capistrano-devel', '>=3.0.0'
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# To use debugger
# gem 'debugger'
