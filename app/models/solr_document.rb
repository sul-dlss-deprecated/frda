# -*- encoding : utf-8 -*-
require 'open-uri'

class SolrDocument 

  include Blacklight::Solr::Document
  
  self.unique_key = 'id'

  def title(params={})
    length = params[:length] || "long"
    case self.type
      when :page
        page_title(length)
      when :images
        self.send("#{length}_title")
      else
        # this is the same as above,
        # we really don't need when :images
        self.send("#{length}_title")
      end
  end
  
  def page_title(length = "long")
    length == "short" ? "page #{self.page_number}" : "#{self.volume_name} - page #{self.page_number}"
  end
  
  def short_title
    highlighted_fields(:title_short_ftsi)
  end
  
  def long_title
    highlighted_fields(:title_long_ftsi)
  end
  
  def page_number
   # self[:page_num_ssi] || self.page_sequence || "1"
   self.page_sequence # for now, let's just show the page sequence, which is guaranteed to start at 1 and go up to X, page_num_isi is from the TEI and is messy
  end

  def page_sequence
    self[:page_sequence_isi]
  end
  
  def total_pages
    self[:vol_total_pages_is]
  end
      
  def druid
    self[:druid_ssi]
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
    self[:type_ssi] == "page" ? :page : :image
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

  def date
    multivalue_field('search_date_dtsim')
  end
  
  def year
    multivalue_field('search_date_dtsim').map {|d| d.to_date.year }
  end

  def speaker
     multivalue_field('speaker_ssim')
  end
 
  def speeches
    return nil unless self[:spoken_text_ftsimv]
    fields = highlighted_fields(:spoken_text_ftsimv)
    fields.map do |speech|
      Speech.new(speech) unless Speech.new(speech).speech.blank?
    end.compact
  end
 
  def highlighted_speeches
    return nil if speeches.blank?
    highlights = []
    self.speeches.each do |speech|
      highlights << speech if speech.highlighted?
    end
    return nil if highlights.blank?
    highlights
  end
  
  def medium
    self[:medium_ssi]
  end

  def publisher
    self[:publisher_ssi]
  end
  
  def session_title
    highlighted_fields(:session_title_ftsim)
  end
  
  def volume
    self[:vol_num_ssi]
  end

  def volume_name
    self[:vol_title_ssi]
  end
  
  def page_text
    highlighted_fields(:text_ftsiv)
  end
  
  def purl
    "#{Frda::Application.config.purl}/#{self.druid}" unless self.druid.blank?
  end
    
  def pdf_file
    "https://stacks.stanford.edu/file/druid:#{self.druid}/#{self[:vol_pdf_name_ss]}" unless self[:vol_pdf_name_ss].blank? || self.druid.blank?
  end
    
  def tei_file
    "https://stacks.stanford.edu/file/druid:#{self.druid}/#{self[:vol_tei_name_ss]}" unless self[:vol_tei_name_ss].blank? || self.druid.blank?
  end  
  
  def txt_file
    get_actual_txt_file unless @txt_file
    return @txt_file
  end

  def formatted_page_text
    get_actual_txt_file unless @formatted_page_text
    return @formatted_page_text
  end

  def get_actual_txt_file
    base_name="https://stacks.stanford.edu/file/druid:#{self.druid}/"     
    possible_filenames=[self[:ocr_id_ss],self[:ocr_id_ss].gsub('_99_','_'),self[:ocr_id_ss].gsub('_99_','_00_')]
    possible_filenames.each do |file| 
      begin
         full_path="#{base_name}#{file}"
         @formatted_page_text=open(full_path).read.encode('UTF-16le', :invalid => :replace, :replace => '').encode('UTF-8')
         @txt_file=full_path
         break
       rescue
         @formatted_page_text=""
         @txt_file=""
       end
    end
  end
  
  def pdf_file_size
    self[:vol_pdf_size_ls]
  end
    
  def tei_file_size
    self[:vol_tei_size_is]
  end
  
	def multivalue_field(name)
	 self[name.to_sym].nil? ? []: self[name.to_sym]
  end

  def volume_sessions
    response=Blacklight.solr.select(
                                :params => {
                                  :fq => "vol_num_ssi:#{self.volume}",
                                  :"facet.field" => "session_date_title_ssim",
                                  :"facet.limit"=> -1,
                                  :"facet.sort" => "index", 
                                  :rows => 0
                                }
                              )['facet_counts']['facet_fields']['session_date_title_ssim']
    sessions=response.values_at(* response.each_index.select {|i| i.even?}) # now just extract the actual terms, and not the occurences
    return sessions.map {|session| session.split("-|-")[1]}
  end
  
  def images(params={})
    return [] unless self.has_key?(blacklight_config.image_identifier_field)
    size=params[:size] || :default
    download=params[:download] || false
    format=params[:format] || "jpg"
    size=:full if download
    stacks_url = Frda::Application.config.stacks_url
    self[blacklight_config.image_identifier_field].map do |image_id|
      url="#{stacks_url}/#{self.druid}/#{image_id.chomp(File.extname(image_id))}#{SolrDocument.image_dimensions[size]}"
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
  
  
  def mods
    return nil unless self[:mods_xml]
    @mods ||= Stanford::Mods::Record.new.from_str(self[:mods_xml], false)
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
  
  def highlighted_fields(key)
    return [] unless self[key]
    if self.highlight_field(key)
      self.highlight_field(key)
    else
      [self[key]].flatten
    end
  end
  
  def blacklight_config
    CatalogController.blacklight_config
  end
end
