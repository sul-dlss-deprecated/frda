# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Frda::Application.initialize!

Frda::Application.config.purl = "http://purl.stanford.edu"