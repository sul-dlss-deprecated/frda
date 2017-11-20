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

1. Start solr and load the fixtures: (you should first stop any solr processes if you have multiple solr-related projects):

        solr_wrapper
        rake frda:index_fixtures

1. Migrate the database.  Note that the solr instance needs to be available to run any migrations, so start Solr first!

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

    rake ci

## Useful commands for debugging

rails console
doc=Item.find('wg983ft3682_00_0004')
puts doc.inspect
puts doc['type_ssi']

## Timeline of the Revolution

The timeline of the revolution widget shown on the home page comes from an external service, with data in a Google Sheet.

Documentation for how the widget is created via a spreadsheet is here: https://timeline.knightlab.com/docs/using-spreadsheets.html
The live FRDA spreadsheet is referenced in Jira ticket #FRDA-274

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

## Custom Methods

There is a custom "link_back_to_catalog" method in app/helpers/blacklight_helper.rb
If you update Blacklight, you should confirm if this method still works or compare with the equivalent method in the latest version of blacklight.  The method is responsible for generating a "back to results" link from item detail pages.

## Indexing

There is a custom indexing app for FRDA that is quite out of date (as of June 2016) and non-operational.  It is still in the DLSS AFS space (under "dev/dlss/git/digital_collection_sites/frda-indexer.git") and not available in github.  To reindex material you would need to upgrade to the latest harvestdor stack.
