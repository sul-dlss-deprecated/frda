class Collection

  # a quick way to get the collection object from solr
  
  def self.ap
    collection=Blacklight.solr.get 'select',:params=>{:q=>Frda::Application.config.ap_id}
    return SolrDocument.new(collection['response']['docs'][0])
  end
  
  def self.images
    collection=Blacklight.solr.get 'select',:params=>{:q=>Frda::Application.config.images_id}
    return SolrDocument.new(collection['response']['docs'][0])    
  end

end