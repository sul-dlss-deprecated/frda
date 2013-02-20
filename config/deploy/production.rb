set :rails_env, "production"
set :deployment_host, "frda-prod.stanford.edu"
set :bundle_without, [:deployment,:development,:test,:staging]

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true

after "deploy:create_symlink", "db:loadseeds"
