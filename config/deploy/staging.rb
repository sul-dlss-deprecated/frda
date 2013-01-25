set :rails_env, "staging"
set :deployment_host, "frda-stage.stanford.edu"
set :bundle_without, [:deployment, :development, :test]

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true

after "deploy:update_code", "db:symlink_sqlite"
after "deploy", "db:loadfixtures"
