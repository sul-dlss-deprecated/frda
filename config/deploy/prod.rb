server 'sul-frda-prod.stanford.edu', user: 'frda', roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, "production"

set :bundle_without, %w{development test staging}.join(' ')
