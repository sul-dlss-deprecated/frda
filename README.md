# FRDA Collection

[![Build Status](https://travis-ci.org/sul-dlss/frda.svg?branch=master)](https://travis-ci.org/sul-dlss/frda)
This is a Blacklight application for the FRDA Collection at Stanford University.

## Getting Started

1. Checkout the code

        git clone https://github.com/sul-dlss/frda.git

1. [Optional] If you want to use rvmrc to manage gemsets, copy the .rvmrc example files:

        cp .rvmrc.example .rvmrc
        cp deploy/.rvmrc.example deploy/.rvmrc
        cd ..
        cd frda
        [accept gemfile]

1. Install dependencies via bundler:

        bundle install

1. Remove the jetty that is checked into git and then set up local jetty and copy config files:

        rm -fr jetty
        git submodule init
        git submodule update
        rake frda:config

1. Start solr and load the fixtures: (you should first stop any other jetty processes if you have multiple jetty-related projects):

        rake jetty:start
        rake frda:index_fixtures

1. Migrate the database.  Note that the solr instance (i.e. jetty) needs to be available to run any migrations, so start Jetty first!

        rake db:migrate
        rake db:seed

1. Start Rails:

        rails s

1. Go to <http://localhost:3000>

## Deployment

    cap production deploy # for production
    cap staging deploy # for staging
    cap development deploy # for development

You must specify a branch or tag to deploy.  You can deploy the latest by specifying "master"

## Testing

During development, you can run the test suite locally by running:

    rake local_ci

This will stop the development jetty, force you into the test environment, start jetty, start solr,
delete all the records in the test solr core, index all fixtures in `spec/fixtures`, run `db:migrate` in test,
then run the tests, and then restart development jetty

If your jetty is not currently running, you can start it and run all of the tests with

    rake ci

## Solr Fields in Fixtures

The following fields are important for the web app to work correctly and are required for each kind of item

AP Page Item:

id - can be anything
druid_ssi - must be set to the druid of the top-level parent volume item
title_ssi - the title of the item
type_ssi - must be "page"
collection_ssi - must be "Archives parlementaires"
volume_ssi - must be set to the id of the parent (which could be the top level volume or could be a subvolume)
image_id_ssm - must be the base filename of the image to show from the parent volume item (e.g. "T00000001") - no .jp2 extension required

Image Items:

id - this should be set to the druid of the item
druid_ssi - must be set to the druid of the item
collection_ssi - must be "Images de la Révolution française"
image_id_ssm - must be the base filename of the image to show (e.g. "T00000001") - no .jp2 extension required
type_ssi - must be "image"

## Utils

To reset jetty and solr back to their initial state:

    rake frda:jetty_nuke
