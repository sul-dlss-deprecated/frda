# -*- encoding : utf-8 -*-
class SolrDocument 

  include Blacklight::Solr::Document
  
  self.unique_key = 'id'

  def title
    self[:title_tsi]
  end
  
  def druid
    self[:druid_ssi]
  end
  
  def description(language=I18n.default_locale)
    multivalue_field("description_#{language}_tsim")
  end

  def subject
    multivalue_field('subject_ssim')
  end

  def person
    multivalue_field('person_ssim')
  end

  def format
    multivalue_field('format_ssim')
  end

  def copyright
    self[:copyright_ssi]
  end

  def year
    self[:year_ssi]
  end

  def source
    self[:source_ssi]
  end

  def type
    self[:type_ssi]
  end
  
  def medium
    self[:medium_ssi]
  end

  def publisher
    self[:publisher_ssi]
  end
  
  def purl
    "#{Frda::Application.config.purl}/#{self.druid}" unless self.collection?
  end
    
	def multivalue_field(name)
	  self[name.to_sym].nil? ? ['']: self[name.to_sym]
  end

  def images(size=:default)
    return [] unless self.has_key?(blacklight_config.image_identifier_field)
    stacks_url = Frda::Application.config.stacks_url
    self[blacklight_config.image_identifier_field].map do |image_id|
      image_druid=(self.collection? ? "" : "#{self.druid}/")  # collections include the druid of the image to use, items don't need it since we know the druid
      "#{stacks_url}/#{image_druid}#{image_id.chomp('.jp2')}#{SolrDocument.image_dimensions[size]}.jpg"
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

   def ap_item?
     self.has_key?(blacklight_config.collection_member_identifying_field) and self[blacklight_config.collection_member_identifying_field]==Frda::Application.config.ap_id
   end
  
   def images_item?
     self.has_key?(blacklight_config.collection_member_identifying_field) and self[blacklight_config.collection_member_identifying_field]==Frda::Application.config.images_id    
   end
   
   def collection?
     self.has_key?(blacklight_config.collection_identifying_field) and 
       self[blacklight_config.collection_identifying_field].include?(blacklight_config.collection_identifying_value)
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
