set :rails_env, "staging"
set :deployment_host, "frda-stage.stanford.edu"
set :bundle_without, [:deployment, :development, :test]

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true

after "deploy:finalize_update", "db:symlink_sqlite"
