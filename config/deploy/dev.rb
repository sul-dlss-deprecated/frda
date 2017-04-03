server 'sul-frda-dev.stanford.edu', user: 'frda', roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, "development"

set :assets_roles, [:none]

set :bundle_without, %w{production staging}.join(' ')
