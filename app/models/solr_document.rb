# -*- encoding : utf-8 -*-
class SolrDocument 

  include Blacklight::Solr::Document
  
  self.unique_key = 'id'

  def title
    self[:title_tsi]
  end
  
  def date
    multivalue_field('unit_date_ssim')
  end

  def description
    multivalue_field('extent_ssim')    
  end

  def people
    multivalue_field('personal_name_ssim')    
  end

  def families
    multivalue_field('family_name_ssim')
  end

  def corporations
    multivalue_field('corporate_name_ssim')
  end

  def location
    multivalue_field('geographic_name_ssim')
  end

  # grab the indexed coordinates, which include location name, latitude, and longitude, delimited by a pipe, and return an array of hashes, which makes them easier to work with
  def coordinates
    raw_coords=multivalue_field('coordinates_ssim')
    coords = []
    raw_coords.each do |raw_coord|
       split_coord=raw_coord.split('|')
       coords << {:name=>split_coord[0],:lat=>split_coord[1],:lon=>split_coord[2]}
    end  
    return coords  
  end
    
  def notes
    multivalue_field('description_tsim')
  end
  
  def purl
    self[:purl_ssi]
  end
  
  def level
    multivalue_field(blacklight_config.folder_identifier_field).first
  end

  def series
    multivalue_field('series_ssim').first
  end
          
  def box
    multivalue_field(blacklight_config.box_identifying_field).first
  end

  def folder
    multivalue_field(blacklight_config.folder_identifying_field).first    
  end
  
	def multivalue_field(name)
	  self[name.to_sym].nil? ? ['']: self[name.to_sym]
  end

  def images(size=:default)
    return [] unless self.has_key?(blacklight_config.image_identifier_field)
    stacks_url = Frda::Application.config.stacks_url
    self[blacklight_config.image_identifier_field].map do |image_id|
      "#{stacks_url}/#{self["druid_ssi"]}/#{image_id.chomp('.jp2')}#{SolrDocument.image_dimensions[size]}.jpg"
    end
  end

  def first_image(size=:default)
    return "http://placehold.it/100x100" unless self.has_key?(blacklight_config.image_identifier_field)
    stacks_url = Frda::Application.config.stacks_url
    images(size).first
  end
  
   def self.image_dimensions
     options = {:default => "_thumb",
                :square   => "_square",
                :thumb => "_thumb" }
   end
  

  def collection?
    self.has_key?(blacklight_config.collection_identifying_field) and 
      self[blacklight_config.collection_identifying_field].include?(blacklight_config.collection_identifying_value)
  end
  
  def collection_member?
    self.has_key?(blacklight_config.collection_member_identifying_field) and 
      !self[blacklight_config.collection_member_identifying_field].blank?
  end
  
  def volume?
    self.has_key?(blacklight_config.volume_identifying_field) and 
      self[blacklight_config.volume_identifying_field] == blacklight_config.volume_identifying_value
  end
  
  def pages
    return nil unless volume?
    @pages ||= CollectionMembers.new(
                 Blacklight.solr.select(
                   :params => {
                     :fq => "#{blacklight_config.pages_identifying_field}:\"#{self[SolrDocument.unique_key]}\"",
                     :rows => blacklight_config.collection_member_grid_items.to_s
                   }
                 )
               )
  end
  
  
  # Return a SolrDocument object of the parent collection of a collection member
  def collection
    return nil unless collection_member?
    @collection ||= SolrDocument.new(
                      Blacklight.solr.select(
                        :params => {
                          :fq => "#{SolrDocument.unique_key}:\"#{self[blacklight_config.collection_member_identifying_field]}\""
                        }
                      )["response"]["docs"].first
                    )
  end
  
  # Return a CollectionMembers object of all the members of a collection
  def collection_members
    return nil unless collection? or volume?
    @collection_members ||= CollectionMembers.new(
                              Blacklight.solr.select(
                                :params => {
                                  :fq => "#{blacklight_config.collection_member_identifying_field}:\"#{self[SolrDocument.unique_key]}\"",
                                  :rows => blacklight_config.collection_member_grid_items.to_s
                                }
                              )
                            )
  end
  
  # Return a CollectionMembers object of all of the siblins a collection member (including self)
  def collection_siblings
    return nil unless collection_member?
    @collection_siblings ||= CollectionMembers.new(
                               Blacklight.solr.select(
                                 :params => {
                                   :fq => "#{blacklight_config.collection_member_identifying_field}:\"#{self[blacklight_config.collection_member_identifying_field].first}\"", 
                                   :rows => blacklight_config.collection_member_grid_items.to_s
                                 }
                               )
                             )
  end
  
  # Return an Array of collection SolrDocuments
  def all_collections
    @all_collections ||= Blacklight.solr.select(
      :params => {
        :fq => "#{blacklight_config.collection_identifying_field}:\"#{blacklight_config.collection_identifying_value}\"",
        :rows => "10"
      }
    )["response"]["docs"].map do |document|
      SolrDocument.new(document)
    end
  end
  
  # The following shows how to setup this blacklight document to display marc documents
  extension_parameters[:marc_source_field] = :marc_display
  extension_parameters[:marc_format_type] = :marcxml
  use_extension( Blacklight::Solr::Document::Marc) do |document|
    document.key?( :marc_display  )
  end
  
  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Solr::Document::Email )
  
  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Solr::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Solr::Document::DublinCore)    
  field_semantics.merge!(    
                         :title => "title_tsi",
                         :author => "author_display",
                         :language => "language_facet",
                         :format => "format_ssim"
                         )

                         
  private
  
  def blacklight_config
    CatalogController.blacklight_config
  end
end
