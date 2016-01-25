server 'sul-frda-stage.stanford.edu', user: 'frda', roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, "production"
