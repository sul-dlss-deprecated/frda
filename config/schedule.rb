set :output, "/opt/app/frda/frda-app/shared/log/cron_log.log"

# Learn more: http://github.com/javan/whenever

every 1.days, :roles => [:app] do
  rake "blacklight:delete_old_searches[5]"
end
