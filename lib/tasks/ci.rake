require 'solr_wrapper' unless Rails.env.production?
require 'rest_client'

desc "Run continuous integration suite"
task :ci do
  unless Rails.env.test?
    system("rake ci RAILS_ENV=test")
  else
    SolrWrapper.wrap do |solr|
      solr.with_collection do
        Rake::Task["frda:refresh_fixtures"].invoke
        Rake::Task["db:migrate"].invoke
        Rake::Task["db:seed"].invoke
        Rake::Task["rspec"].invoke
      end
    end
  end
end

namespace :frda do
  desc "Delete and index all fixtures in solr"
  task :refresh_fixtures do
    Rake::Task["frda:delete_records_in_solr"].invoke
    Rake::Task["frda:index_fixtures"].invoke
  end

  desc "Delete all records in solr"
  task :delete_records_in_solr do
    puts "Deleting all solr documents from #{Blacklight.solr.options[:url]}"
    RestClient.post "#{Blacklight.solr.options[:url]}/update?commit=true", "<delete><query>*:*</query></delete>" , :content_type => "text/xml"
  end
end
