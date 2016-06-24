# config valid only for Capistrano 3.1
lock '3.5.0'

set :application, 'frda'
set :repo_url, 'https://github.com/sul-dlss/frda.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/opt/app/frda/frda-app'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/solr.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5
set :bundle_audit_ignore, %w{CVE-2015-3226 OSVDB-131677}

after  "deploy:finished", "db:seed"  # the db:seed method loads data that the FRDA site needs to operate correctly, including info shown on this page: /en/images and /fr/images
# db:seed should be run after each deploy

before 'deploy:publishing', 'squash:write_revision'
