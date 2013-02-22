# -*- encoding : utf-8 -*-
class SolrDocument 

  include Blacklight::Solr::Document
  
  self.unique_key = 'id'

  def title(params={})
    length=params[:short].nil? ? "long" : "short" 
    case self.type
      when "page"
        self.page_title
      when "volume"
        self.volume_name
      when "image"
        self[:"title_#{length}_ssi"]
      else
        self[:"title_#{length}_ssi"]
      end
  end
  
  # for AP page items
  def page_title 
    "#{self.volume_name}"
  end
  
  def page_number
    self[:page_num_ssi]
  end
  
  def druid
    self[:druid_ssi]
  end
  
  def description(language=I18n.default_locale)
    multivalue_field("description_#{language[0]}tsim")
  end
  
  def catalog_heading(language=I18n.default_locale)
    multivalue_field("catalog_heading_#{language[0]}tsimv").map do |field|
      field.split("--").map do |value|
        value.strip
      end
    end
  end

  def collector
    multivalue_field('collector_ssim')
  end

  def type
    self[:type_ssi]
  end
  
  def format
    multivalue_field('doc_type_ssim')
  end

  def genre
    multivalue_field('genre_ssim')
  end

  def artist
    multivalue_field('artist_ssim')
  end

  def year
    multivalue_field('date_issued_ssim')
  end

  def speaker
     multivalue_field('speaker_ssim')
 end
     
  def medium
    self[:medium_ssi]
  end

  def publisher
    self[:publisher_ssi]
  end
  
  def volume
    self[:vol_num_ssi]
  end

  def volume_name
    self[:vol_title_ssi]
  end
  
  def page_text
    self[:text_ftsiv]
  end
  
  def purl
    "#{Frda::Application.config.purl}/#{self.druid}" unless self.druid.blank?
  end
    
  def pdf_file
    "https://stacks.stanford.edu/file/druid:#{self.druid}/#{druid}.pdf" unless self.druid.blank?    
  end
    
  def tei_file
    "https://stacks.stanford.edu/file/druid:#{self.druid}/#{druid}.xml" unless self.druid.blank?          
  end  
  
	def multivalue_field(name)
	  self[name.to_sym].nil? ? ['']: self[name.to_sym]
  end

  def images(params={})
    return [] unless self.has_key?(blacklight_config.image_identifier_field)
    size=params[:size] || :default
    download=params[:download] || false
    format=params[:format] || "jpg"
    size=:full if download
    stacks_url = Frda::Application.config.stacks_url
    self[blacklight_config.image_identifier_field].map do |image_id|
      image_druid=(self.collection? ? "" : "#{self.druid}/")  # collections include the druid of the image to use, items don't need it since we know the druid
      url="#{stacks_url}/#{image_druid}#{image_id.chomp(File.extname(image_id))}#{SolrDocument.image_dimensions[size]}"
      if download
        url += "?action=download" 
      else  
        url += ".#{format}" unless format == 'none'
      end
      url
    end
  end
  
  def first_image(params={})
    return "http://placehold.it/100x100" unless self.has_key?(blacklight_config.image_identifier_field)
    stacks_url = Frda::Application.config.stacks_url
    images(params).first
  end
  
   def self.image_dimensions
     options = {:default => "_thumb",
                :square   => "_square",
                :thumb => "_thumb",
                :medium => "_medium",
                :full => "" }
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
   
   def total_pages
     self.images_item? ? 1 : Blacklight.solr.select(:params => {:fq => "druid_ssi:\"#{self.druid}\"",:rows=>0})["response"]["numFound"]
   end
   
   # TODO FIX -- this must be a better way to do this via solr -- this method only works with two levels of hierarchy ??
   def ancestors
     ancestors = []
     # parent=self.parent
     # if parent 
     #   grandparent = parent.parent
     #   ancestors << grandparent if grandparent
     #   ancestors << parent
     # end
     # return ancestors
   end
   
   # return the item whose id is equal to my volume id
   def parent
     # query="id:\"#{self[blacklight_config.parent_identifying_field.to_sym]}\""
     #     parents = Blacklight.solr.select(
     #                                 :params => {
     #                                   :fq => query  }
     #                               )
     #     docs=parents["response"]["docs"].map{|d| SolrDocument.new(d) }
     #     docs.size == 0 ? nil : docs.first
    nil
    # TODO FIX!
   end

   # return the items whose volume id is equal to my id
   def children
     # query="#{blacklight_config.parent_identifying_field}:\"#{self.id}\""
     # ancestors = Blacklight.solr.select(
     #                             :params => {
     #                               :fq => query  }
     #                           )
     # return ancestors["response"]["docs"].map{|d| SolrDocument.new(d) }
     nil
    # TODO FIX!
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
                         :format => "doc_type_ssim"
                         )

                         
  private
  
  def blacklight_config
    CatalogController.blacklight_config
  end
end
