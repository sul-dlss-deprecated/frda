# Bassi Veratti Collection

This is a Blacklight application for the Bassi Verati Collection at Stanford University.

## Getting Started

1. Checkout the code

        git clone /afs/ir.stanford.edu/dev/dlss/git/digital_collection_sites/bassi_veratti.git

1. [Optional] If you want to use rvmrc to manage gemsets, copy the .rvmrc example files:

        cp .rvmrc.example .rvmrc
        cp deploy/.rvmrc.example deploy/.rvmrc
        cd ..
        cd bassi_veratti

1. Install dependencies via bundler for both the main and deploy directories:

        bundle install
        cd deploy
        bundle install
        cd ..

1. Set up local jetty and copy config files

        git submodule init
        git submodule update
        rake bassi:config

1. Migrate the database:

        rake db:migrate
        rake db:migrate RAILS_ENV=test
				rake db:seed
				rake db:seed RAILS_ENV=test

1. Start solr and load the fixtures: (you should first stop any other jetty processes if you have multiple jetty-related projects):

        rake jetty:start
        rake bassi:index_fixtures
				rake bassi:parse-ead

1. Start Rails:

        rails s

1. Go to <http://localhost:3000>


## Deployment

    cd deploy
    cap production deploy # for production
    cap production staging # for staging
    cap production development # for development

You must specify a branch or tag to deploy.  You can deploy the latest by specifying "master"

## Testing

You can run the test suite locally by running:

    rake local_ci

This will stop development jetty, force you into the test environment, start jetty, start solr,
delete all the records in the test solr core, index all fixtures in `spec/fixtures`, run `db:migrate` in test,
then run the tests, and then restart development jetty

## Collection Highlights

The collection highlights shown on the home page are stored in MySQL.  The database entries are created in db/seeds.rb
For each collection highlight, you need a name in English and Italian, a local placeholder image to show (placed in the assets/image folder), and a description (not shown).
You also need a list of IDs that belong in the collection.

## Utils

To reset jetty and solr back to their initial state:

    rake bassi:jetty_nuke