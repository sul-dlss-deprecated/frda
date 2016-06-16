# -*- encoding : utf-8 -*-
require 'open-uri'

class SolrDocument

  include Blacklight::Solr::Document
  include ModsDisplay::ModelExtension

  self.unique_key = 'id'

  mods_xml_source do |model|
    model.mods_xml_for_mods_display
  end

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
   self[:page_num_ssi] || ".."
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

  def highlighted_spoken_and_unspoken_text
    return nil unless highlighted_spoken_text? or highlighted_unspoken_text?
    [highlighted_spoken_text, highlighted_unspoken_text].flatten.compact.sort_by{ |text| text.page_id }.group_by(&:page_id)
  end

  def spoken_text
    return nil unless self[:spoken_text_ftsimv]
    fields = highlighted_fields(:spoken_text_ftsimv)
    @spoken_text ||= fields.map do |text|
      SpokenText.new(text) unless SpokenText.new(text).text.blank?
    end.compact
  end

  def unspoken_text
    return nil unless self[:unspoken_text_ftsimv]
    fields = highlighted_fields(:unspoken_text_ftsimv)
    @unspoken_text ||= fields.map do |text|
      UnspokenText.new(text) unless UnspokenText.new(text).text.blank?
    end.compact
  end

  def highlighted_spoken_text?
    return true unless highlighted_spoken_text.blank?
  end

  def highlighted_spoken_text
    highlighted_text_field(spoken_text)
  end

  def highlighted_unspoken_text?
    return true unless highlighted_unspoken_text.blank?
  end

  def highlighted_unspoken_text
    highlighted_text_field(unspoken_text)
  end

  def highlighted_text_field(text_field)
    return nil if text_field.blank?
    highlights = []
    text_field.each do |text|
      highlights << text if text.highlighted?
    end
    return nil if highlights.blank?
    highlights
  end

  def page_range_in_session
    numbers = pages_in_session.map do |_, page|
      page.page_number
    end
    (numbers.select{|number| !number.blank?}.first...numbers.select{|number| !number.blank?}.last)
  end

  def pages_in_session(options={})
    return nil unless self[:pages_ssim]
    urls = {}
    self[:pages_ssim].map do |id_with_page|
      image_id = id_with_page.split("-|-")[0]
      page = id_with_page.split("-|-")[1]
      size = options[:size] || :default
      format = options[:format] || "jpg"
      urls[image_id] = OpenStruct.new(
        :page_number => page,
        :url => "#{Frda::Application.config.stacks_url}/image/#{self[:druid_ssi]}/#{image_id.chomp(File.extname(image_id))}#{SolrDocument.image_dimensions[size]}.#{format}"
      )
    end
    urls
  end

  def truncated_full_text(options={})
    return nil unless self[:text_ftsiv]
    snippet = options[:length] || 100
    return [self[:text_ftsiv]] if self[:text_ftsiv].length < ((snippet * 2) + (snippet / 2))
    [self[:text_ftsiv][0..snippet], "...", self[:text_ftsiv][-snippet..-1]]
  end

  def medium
    self[:medium_ssim]
  end

  def publisher
    self[:publisher_ssi]
  end

  def session_title
    if self[:div2_title_ssi]
      return highlighted_fields(:div2_title_ssi)
    elsif self[:session_title_ftsi]
      return highlighted_fields(:session_title_ftsi)
    elsif self[:session_title_ftsim]
      return highlighted_fields(:session_title_ftsim)
    end
    []
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

  # the ocr file on the stacks can unfortunately be named by various possibilities, so we have to look for each
  def possible_ocr_filenames
    ocr_id=self[:ocr_id_ss]
    if ocr_id.blank?
      []
    else
      [ocr_id,ocr_id.gsub('_99_','_'),ocr_id.gsub('_99_','_00_')]
    end
  end

  def get_actual_txt_file
    base_name="#{Frda::Application.config.stacks_url}/file/druid:#{self.druid}/"
    @formatted_page_text=""
    @txt_file=""
    possible_ocr_filenames.each do |file|
      txt_file="#{base_name}#{file}"
      Rails.logger.info("app/models/solr_document.rb#get_actual_txt_file: Looking for OCR file #{txt_file}")
      begin
        response = Faraday.get(txt_file)
        if response.success? # we found it
          Rails.logger.info("....found #{txt_file}")
          @txt_file=txt_file # cache the filename
          text_data = response.body
          detect_encoding = CharDet.detect(text_data)
          # Check to make sure the response body encoding is UTF-8 as expected using https://rubygems.org/gems/rchardet
          # If not UTF-8, convert from current encoding to UTF-8 using string encode or the following algorithm.
          # After sampling text files that are not encoded as UTF-8, there were some encoded as nil, windows-1255 (hebrew encoding for Microsoft Word),
          # and Big5 (chinese character encoding). To begin with, assume all are Windows-1252 (Latin alphabet)
          if detect_encoding['encoding'].downcase != 'utf-8'
            if (detect_encoding['encoding'].downcase.include?('windows') ||
               detect_encoding['encoding'].downcase.include?('big5') ||
               detect_encoding['encoding'].downcase.include?('8859') ||
               detect_encoding['encoding'].downcase.include?('tis') ||
               detect_encoding['encoding'] == nil)
              @formatted_page_text = text_data.encode("UTF-8", "Windows-1252")
            else
              @formatted_page_text = text_data.encode("UTF-8", detect_encoding['encoding'])
            end
          else
            @formatted_page_text = text_data.force_encoding('UTF-8').scrub
          end
          break # don't bother checking for more filename possibilities once we find one
        end # end check for success response code
      rescue StandardError => e
        Rails.logger.error("Error in app/models/solr_document.rb#get_actual_txt_file on #{txt_file}.  Exception raised was #{e.message}.")
       end # rescue block
     end # loop over possible filenames
  end # get_actual_txt_file method

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
    self[blacklight_config.image_identifier_field].map do |image_id|
      url="#{Frda::Application.config.stacks_url}/image/#{self.druid}/#{image_id.chomp(File.extname(image_id))}#{SolrDocument.image_dimensions[size]}"
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
    images(params).first
  end


  def mods
    return nil unless self[:mods_xml]
    @mods ||= Stanford::Mods::Record.new.from_str(self[:mods_xml], false)
  end

  def mods_xml_for_mods_display
    return nil unless self[:mods_xml]
    xml = Nokogiri::XML(self[:mods_xml]).remove_namespaces!
    xml.search("//subject[@displayLabel='Catalog heading']").each do |node|
      node.remove
    end
    xml.to_s
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
      if self.highlight_field(key).first.scan("-|-").length > 3
        if key.to_s.include?("unspoken")
          split_highlighted_unspoken_field_glob(self.highlight_field(key))
        else
          split_highlighted_spoken_field_glob(self.highlight_field(key))
        end
      else
        self.highlight_field(key)
      end
    else
      [self[key]].flatten
    end
  end

  def split_highlighted_unspoken_field_glob(field)
    split_field_glob(field).map do |(id, text)|
      "#{id}-|-#{text}" if text.include?("<em>")
    end.compact
  end

  def split_highlighted_spoken_field_glob(field)
    split_field_glob(field).map do |(id, delimited_text)|
      if delimited_text
        speaker, text = delimited_text.split("-|-")
        "#{id}-|-#{speaker}-|-#{text}" if text.include?("<em>")
      end
    end.compact
  end

  def split_field_glob(field)
    split_fields = field.join(" ").split(/(\w+_\d{2}_\d{4})-\|-/)
    split_fields.shift # remove first element if blank
    split_fields.each_slice(2).to_a # returns an array of arrays: [["id", "text_value"], ["id", "text_value"], ["id", "text_value"]]
  end

  def blacklight_config
    CatalogController.blacklight_config
  end
end
