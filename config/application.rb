# encoding: utf-8

require File.expand_path('../boot', __FILE__)

require 'rails/all'
Bundler.require(*Rails.groups)

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups)
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

VERSION = File.read('VERSION')

module Frda
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.enforce_available_locales = false

    config.i18n.default_locale = :en
    config.allowed_locales = [:en,:fr]
    config.i18n.fallbacks = true
    # rails will fallback to en, no matter what is set as config.i18n.default_locale
    config.i18n.fallbacks = [:en]

    config.cache_store = :file_store, "tmp/cache"

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enable the asset pipeline
    config.assets.enabled = true
    # Default SASS Configuration, check out https://github.com/rails/sass-rails for details
    config.assets.compress = !Rails.env.development?

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = VERSION

    config.assets.logger = false

  end
end

Frda::Application.config.version = VERSION # read from VERSION file at base of website

Frda::Application.config.ap_id = "Archives parlementaires"  # the solr doc ID of the ap collection object, each associated item must reference this collection-id in collection_ssi
Frda::Application.config.images_id = "Images de la Révolution française"  # the solr doc ID of the images collection object, each associated item must reference this collection-id in collection_ssi

Frda::Application.config.stacks_url = YAML.load_file("#{Rails.root}/config/stacks.yml")[Rails.env]["url"]
Frda::Application.config.contact_us_topics = {'error'=>'frda.contact.problem'} # sets the list of topics shown in the contact us page
Frda::Application.config.contact_us_recipients = {'error'=>'digcoll@jirasul.stanford.edu'} # sets the email address for each contact us topic configed above
Frda::Application.config.contact_us_cc_recipients = {'error'=>'frda-problems@jirasul.stanford.edu'} # sets the CC email address for each contact us topic configed above
