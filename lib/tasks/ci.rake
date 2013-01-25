require 'jettywrapper' unless Rails.env.production?
require 'rest_client'

desc "Run continuous integration suite"
task :ci do
  unless Rails.env.test?  
    system("rake ci RAILS_ENV=test")
  else
    Jettywrapper.wrap(Jettywrapper.load_config) do
      Rake::Task["frda:refresh_fixtures"].invoke
      Rake::Task["rspec"].invoke
    end
  end
end

desc "Stop dev jetty, run `rake ci`, start dev jetty."
task :local_ci do  
  system("rake jetty:stop")
  system("rake frda:jetty_nuke RAILS_ENV=test")
  system("rake db:migrate RAILS_ENV=test")  
  system("rake frda:index_fixtures RAILS_ENV=test")
  system("rspec")
  system("rake jetty:stop RAILS_ENV=test")  
  system("rake jetty:start")
end


namespace :frda do

  desc "Copy FRDA configuration files"
  task :config do
    cp("#{Rails.root}/config/database.yml.example", "#{Rails.root}/config/database.yml") unless File.exists?("#{Rails.root}/config/database.yml")
    cp("#{Rails.root}/config/solr.yml.example", "#{Rails.root}/config/solr.yml") unless File.exists?("#{Rails.root}/config/solr.yml")
    cp("#{Rails.root}/solr_conf/solr.xml","#{Rails.root}/jetty/")
    cp("#{Rails.root}/solr_conf/conf/schema.xml","#{Rails.root}/jetty/solr/blacklight-core/conf")
    cp("#{Rails.root}/solr_conf/conf/solrconfig.xml","#{Rails.root}/jetty/solr/blacklight-core/conf")    
  end
  
  desc "restore jetty to initial state"
  task :jetty_nuke do
    puts "Nuking jetty"
    # Restore jetty submodule to initial state.
    Rake::Task['jetty:stop'].invoke
    Dir.chdir('jetty') {
      system('git reset --hard HEAD') or exit
      system('git clean -dfx')        or exit
    }
    Rake::Task['frda:config'].invoke
    Rake::Task['jetty:start'].invoke
  end
  
  desc "Delete and index all fixtures in solr"
  task :refresh_fixtures do
    Rake::Task["frda:delete_records_in_solr"].invoke
    Rake::Task["frda:index_fixtures"].invoke
  end
  
  desc "Delete all records in solr"
  task :delete_records_in_solr do
   unless Rails.env.production?
      puts "Deleting all solr documents from #{Blacklight.solr.options[:url]}"
      RestClient.post "#{Blacklight.solr.options[:url]}/update?commit=true", "<delete><query>*:*</query></delete>" , :content_type => "text/xml"
    else
      puts "Did not delete since we're running under the #{Rails.env} environment and not under test. You know, for safety."
    end
  end
end