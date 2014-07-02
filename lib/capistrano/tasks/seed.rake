namespace :db do
  task :seed do
    on roles(:all) do |host|
      within release_path do
        with rails_env: fetch(:rails_env) do
          rake 'db:seed'
        end
      end
    end
  end
end
