source 'https://rubygems.org'
source 'http://sul-gems.stanford.edu'

gem 'bundler', '>= 1.2.0'

ruby "1.9.3"

gem 'rails', '>= 3.2.11'

gem 'google-analytics-rails'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem "blacklight", '~> 4.0.0'
#gem 'eadsax', :git => "https://github.com/sul-dlss/eadsax.git"
gem 'ffi'

gem 'blacklight_dates2svg', '~> 0.0.1.beta3'

gem "coderay"

gem 'stanford-mods'
gem 'mods_display', '~> 0.1.4'

gem 'bootstrap-datepicker-rails'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

group :test do
  gem 'rspec-rails'
  gem 'capybara'
	gem 'launchy'
end

group :development do
	gem 'better_errors'
	gem 'binding_of_caller'
	gem 'meta_request'
	gem 'launchy'
end

group :development, :staging, :test do
  gem 'jettywrapper'
  gem 'sqlite3'
end

group :staging, :production do
  gem 'mysql', "2.8.1"
end

gem 'json', '~> 1.7.7'

gem 'rest-client'
gem 'geocoder'
gem 'jquery-rails'

gem "bootstrap-sass"

gem 'awesome_nested_set'

# gems necessary for capistrano deployment
group :deployment do
  gem 'capistrano'
  gem 'capistrano-ext'
  gem 'rvm-capistrano'
  gem 'lyberteam-devel', '>=1.0.0'
  gem 'lyberteam-gems-devel', '>=1.0.0'
  gem 'net-ssh-krb'
  gem 'gssapi', :git => 'https://github.com/cbeer/gssapi.git'
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# To use debugger
# gem 'debugger'