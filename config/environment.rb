# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Frda::Application.initialize!

Frda::Application.config.purl_plugin_server = "prod"
Frda::Application.config.purl_plugin_location = "//image-viewer.stanford.edu/assets/purl_embed_jquery_plugin.js"
Frda::Application.config.purl = "http://purl.stanford.edu"