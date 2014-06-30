# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
require 'frda/solr_helper'
require 'solr_response_term_frequencies'

class CatalogController < ApplicationController  

  include Blacklight::Catalog
  include Frda::SolrHelper
  include BlacklightDates2SVG
  include ModsDisplay::ControllerExtension

  configure_mods_display do
    # Removing genre links per FRDA-191. I am keeping this commented out
    # as a refernece to how we used the search_link_from_facet_field
    # method in case we would like to re-link genre in the future.

    # genre do
    #   link :search_link_from_facet_field, :field => "genre_ssim", :value => "%value%"
    # end
    subject do
      hierarchical_link true
      link :subject_search_link, :value => '"%value%"'
    end
    resource_type do
      ignore!
    end
    collection do
      ignore!
    end
  end
  
  # The logic to handle the date range queries is being set by the BlacklightDates2SVG gem.
  # If we remove that, but still want date processing, we'll need to explicity require and use the DateRangeSolrQuery gem.
  CatalogController.solr_search_params_logic += [:only_search_div2, :search_within_speeches,
                                                 :proximity_search, :result_view,
                                                 :exclude_highlighting, :pivot_facet_on_ap_landing_page]
  
  before_filter :capture_split_button_options, :capture_drop_down_options, :title_and_exact_search, :only => :index

  def self.political_periods_query(locale)
    opts={}
    PoliticalPeriod.find(:all,:order=>:sort_order).each do |period|
      start_date = "#{DateTime.parse(period.start_date).strftime("%Y-%m-%d")}T00:00:00Z"
      end_date = "#{(DateTime.parse(period.end_date) + 1.day).strftime("%Y-%m-%d")}T00:00:00Z"
      range_query = "search_date_dtsim:[#{start_date} TO #{end_date}]"
      opts[:"period_#{period.id}"] = {:label => period.send("name_#{locale}").force_encoding("UTF-8"), :fq => range_query}
    end if ActiveRecord::Base.connection.table_exists? 'political_periods'
    opts
  end
  
  def self.collection_highlights(locale)
    opts = {}
    CollectionHighlight.find(:all,:order=>:sort_order).each do |highlight|
      opts[:"highlight_#{highlight.id}"] = {:label => highlight.send("name_#{locale}"), :fq => "id:(#{highlight.query.gsub('or', 'OR')})"}
    end if ActiveRecord::Base.connection.table_exists? 'collection_highlights'
    opts
  end
    
  def current_user; nil; end
  
  def guest_user
    User.find(session[:guest_user_id].nil? ? session[:guest_user_id] = create_guest_user.id : session[:guest_user_id])
  end
  
  def current_or_guest_user
    guest_user
  end
  
  def index
    
    if on_home_page
      @highlights=CollectionHighlight.order("sort_order").limit(3)
    end
    
    if on_collection_highlights_page
      @highlights=CollectionHighlight.order("sort_order")
    end

    if on_images_landing_page
      lang = I18n.locale.to_s.titleize
      @headings = "Category#{lang}".constantize.order("position ASC")
    end

    if group_response?
      (@response, @document_list) = get_grouped_search_results
    else
      (@response, @document_list) = get_search_results
    end

    @filters = params[:f] || []

    respond_to do |format|
      format.html
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
    end

  end

    
   def show
     @mode=params[:mode] # can be set to "ocr" or "flipbook" to show only ocr text or flipbook on AP pages
     super
   end

  # a call to show a new AP page for a given solr doc ID, when ajax will return just the partial, when non ajax will redirect to the correct page
  def show_page
    from_id=params[:from_id]
    druid=params[:id]
    page_num=params[:page_num]
    page_seq=params[:page_seq]
    download_ocr_text=params[:download_ocr_text]
    volume=params[:volume]
    session_title=params[:session_title]
    
    @mode=params[:mode]

    if (page_num.blank? && page_seq.blank?) || !session_title.blank? # if no page number or sequence given, this must be a search for a specific session, so look for the first page in that volume/session
      pages = Blacklight.solr.select(:params =>{:fq => "session_title_sim:\"#{session_title}\"",:"facet.field"=>"session_seq_first_isim",:rows=>0})['facet_counts']['facet_fields']['session_seq_first_isim']
      if pages.size > 0 
        page_seq=pages.first # grab first page sequence number for the first session returned and then look up the page in the given voluem
        response = Blacklight.solr.select(:params =>{:fq => "vol_num_ssi:\"#{volume}\" AND page_sequence_isi:\"#{page_seq}\""})["response"]
        @document = SolrDocument.new(response["docs"].first, response) if response["docs"].size > 0 # assuming we found this page
      end
    else # if a page number or sequeunce is given, use that to find the specific page
      page_query = (page_num.blank? ? "page_sequence_isi:\"#{page_seq}\"" : "page_num_ssi:\"#{page_num}\"")
      response = Blacklight.solr.select(:params =>{:fq => "druid_ssi:\"#{druid}\" AND #{page_query}"})["response"]
      @document = SolrDocument.new(response["docs"].first, response) if response["docs"].size > 0 # assuming we found this page
    end
        
    if request.xhr? # coming an ajax call, just render the new page (or an error message if not found)
        setup_next_and_previous_documents
        render 'show_page',:format=>:js
        return
    elsif download_ocr_text # user requested to download the OCR text, so give it to them
        send_data(@document.formatted_page_text, :filename => "#{@document.title}.txt")
        return
    elsif @document # user needs to see the next page and is not coming an ajax call, we will redirect them on below to the new page
        id=@document.id
    else # page was not found, so we will redirect back to where they started with an error message
        flash[:alert]=t('frda.show.not_found') 
        id=from_id
    end

    redirect_to catalog_path(id,:mode=>@mode)

  end

  def citation
    @ap_purl = params[:purl]
    super
  end

  # an ajax call to get speaker name suggestions for autocomplete on the speaker search box
  def speaker_suggest
    term=params[:term]
    term[0]=term[0].capitalize
    results=Blacklight.solr.select(:params=>{:q=>'collection_ssi:"Archives parlementaires"',:facet=>true,:"facet.field"=>"speaker_ssim",:rows=>0,:"facet.limit"=>50,:"facet.mincount"=>1,:"facet.prefix"=>"#{term}"})
    suggestions=results['facet_counts']['facet_fields']['speaker_ssim']
    @suggestions = suggestions.values_at(* suggestions.each_index.select {|i| i.even?}) # now just extract the actual terms, and not the occurences
    respond_to do |format|
      format.json { render :json => @suggestions }
    end
  end
  
  configure_blacklight do |config|
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = { 
      :qt => 'search',
      :facet => 'true',
      :rows => 10,
      :fl => "*",
      :"facet.mincount" => 1,
      :"hl.usePhraseHighlighter" => true
    }
    
    config.search_date_field = "search_date_dtsim"

    config.collection_highlight_field = "highlight_ssim" 
            
    config.collection_member_identifying_field = "collection_ssi"  # this identifies what overall collection we are in
            
    config.image_identifier_field = "image_id_ssm"

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SolrHelper#solr_doc_params) or 
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    config.default_document_solr_params = {
     :qt => 'search',
     :fl => '*',
     :rows => 1,
     :q => '{!raw f=id v=$id}' 
    }
    
    config.document_index_view_types = ["default", "gallery", "list", "frequency", "covers"]

    # NOT SURE THESE ARE RELEVANT SINCE WE HAVE CUSTOM VIEWS FOR ALL ITEMS  Peter 2/1/2013
    # solr field configuration for search results/index views
    config.index.show_link = 'title_tsi'
    # solr field configuration for document/show views
    config.show.html_title = 'title_tsi'
    config.show.heading = 'title_tsi'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.    
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or 
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.  
    #
    # :show may be set to false if you don't want the facet to be drawn in the 
    # facet bar


    config.add_facet_field 'en_periods_ssim', label: :'frda.nav.timeline_of_events', :show => true,  :query => political_periods_query('en')
    config.add_facet_field 'fr_periods_ssim', label: :'frda.nav.timeline_of_events', :show => true,  :query => political_periods_query('fr')
  
    config.add_facet_field 'en_highlight_ssim', label: :'frda.nav.collection_highlights', :show => false,  :query => collection_highlights('en')
    config.add_facet_field 'fr_highlight_ssim', label: :'frda.nav.collection_highlights', :show => false,  :query => collection_highlights('fr')

    config.add_facet_field 'collection_ssi', label: :'frda.nav.collection'
    config.add_facet_field 'speaker_ssim', label: :'frda.show.people', :show => true, :limit => 15
    
    config.add_facet_field 'doc_type_ssi', label: :'frda.facet.type', :limit => 15
    config.add_facet_field 'medium_ssim', label: :'frda.facet.medium', :limit => 15
    config.add_facet_field 'genre_ssim', label: :'frda.facet.genre', :limit => 15
    config.add_facet_field 'artist_ssim', label: :'frda.facet.artist', :limit => 15
    config.add_facet_field 'collector_ssim', label: :'frda.facet.collector', :limit => 15
    config.add_facet_field 'vol_title_ssi', label: :'frda.facet.volume', :limit => 15
    config.add_facet_field 'div2_title_ssi', label: :'frda.show.session', :show => false
    config.add_facet_field 'search_date_dtsim', label: :"frda.show.date", :show => false
    config.add_facet_field 'result_group_ssort', label: :"frda.show.volume", :show => false
    config.add_facet_field 'div2_ssort', label: :"frda.show.session", :show => false

    config.add_facet_field 'frequency_ssim', label: :"frda.show.frequency", :show => false, :pivot => ["result_group_ssort", "div2_ssort"]

    # config.add_facet_field 'example_query_facet_field', :label => 'Publish Date', :query => {
    #    :years_5 => { :label => 'within 5 Years', :fq => "pub_date:[#{Time.now.year - 5 } TO *]" },
    #    :years_10 => { :label => 'within 10 Years', :fq => "pub_date:[#{Time.now.year - 10 } TO *]" },
    #    :years_25 => { :label => 'within 25 Years', :fq => "pub_date:[#{Time.now.year - 25 } TO *]" }
    # }


    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    # config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 

    config.add_index_field 'level_ssim', label: :'frda.show.level'
    config.add_index_field 'unit_date_ssim', label: :'frda.show.date'
    config.add_index_field 'text_ftsiv', :label => "Spoken Text:", :highlight => true #don't really need an i18n label here since it won't be used.
    config.add_index_field 'spoken_text_ftsmiv', :label => "Spoken Text:", :highlight => true #don't really need an i18n label here since it won't be used.
    config.add_index_field 'title_long_ftsi', :label => "Long Tilte:", :highlight => true #don't really need an i18n label here since it won't be used.
    config.add_index_field 'title_short_ftsi', :label => "Short Title:", :highlight => true #don't really need an i18n label here since it won't be used.
    config.add_index_field 'div2_title_ssi', :label => "Section:", :highlight => true #don't really need an i18n label here since it won't be used.
    

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display 
    config.add_show_field 'level_ssim', label: :'frda.show.level'
    config.add_show_field 'unit_date_ssim', label: :'frda.show.date'
    config.add_show_field 'extent_ssim',  label: :'frda.show.physical_description'
    config.add_show_field 'description_tsim', label: :'frda.show.notes'

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different. 

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise. 
    
    config.add_search_field 'all_fields', label: :'frda.facet.all_fields'
    
    config.add_search_field('title_terms') do |field|
      field.label = :'frda.facet.title'
      field.solr_local_parameters = {
        :qf => '$qf_title',
        :pf => '$pf_title'
      }
    end
    
    config.add_search_field('exact') do |field|
      field.label = :'frda.facet.exact'
      field.solr_local_parameters = {
        :qf => '$qf_exact',
        :pf => '$pf_exact'
      }
    end
    
    config.add_search_field('exact_title') do |field|
      field.label = :'frda.facet.exact_title'
      field.solr_local_parameters = {
        :qf => '$qf_title_exact',
        :pf => '$pf_title_exact'
      }
    end


    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    #config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc', :label => 'relevance'
    #config.add_sort_field 'pub_date_sort desc, title_sort asc', :label => 'year'
    #config.add_sort_field 'author_sort asc, title_sort asc', :label => 'author'
    #config.add_sort_field 'title_sort asc, pub_date_sort desc', :label => 'title'

    # If there are more than this many search results, no spelling ("did you 
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  # Email Action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
  def email
    @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
    if request.post?
      if params[:to]
        url_gen_params = {:host => request.host_with_port, :protocol => request.protocol}
        
        if params[:to].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
          email = RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message]}, url_gen_params)
        else
          flash[:error] = I18n.t('blacklight.email.errors.to.invalid', :to => params[:to])
        end
      else
        flash[:error] = I18n.t('blacklight.email.errors.to.blank')
      end

      unless flash[:error]
        email.deliver 
        flash[:success] = "Email sent"
        if request.xhr?
          render :email_sent, :formats => [:js]
          return
        else
          redirect_to catalog_path(params['id']) 
        end
      end
    end

    unless !request.xhr? && flash[:success]
      respond_to do |format|
        format.js { render :layout => false }
        format.html
      end
    end
  end
  
  def mods
    @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def group_response?
    return true unless params["f"]
    !(params and
        params["f"] and
          ((params["f"]["vol_title_ssi"] and !params["f"]["vol_title_ssi"].blank?) or
           (params["f"]["div2_title_ssi"] and !params["f"]["div2_title_ssi"].blank?)) or
           (params["f"]["collection_ssi"] and params["f"]["collection_ssi"].include?(Frda::Application.config.images_id)) or
           (params["f"]["result_group_ssi"] and params["f"]["result_group_ssi"].include?(Frda::Application.config.images_id)))
  end
  helper_method :"group_response?"
  
  def response_is_grouped?
    @response and @response.is_a?(Frda::GroupedSolrResponse)
  end
  helper_method :"response_is_grouped?"

  private

  def only_search_div2(solr_params, user_params)
    query = "-type_ssi:page"
    if solr_params.has_key?(:fq)
      solr_params[:fq] << query
    else
      solr_params[:fq] = [query]
    end
  end

  def search_within_speeches(solr_params, user_params)
    unless user_params["speeches"].blank? and user_params["by-speaker"].blank?
      solr_params[:q] = "spoken_text_ftsimv:\"aaa#{user_params['by-speaker']}zzz #{user_params['q'].gsub('"','')}\"~10050"
      solr_params[:defType] = "lucene"
    end
  end
  
  def proximity_search(solr_params, user_params)
    if user_params["prox"] and !user_params["words"].blank?
      solr_params[:q] = "\"#{user_params["q"].gsub('"', '')}\""
      solr_params[:qs] = user_params["words"]
    end
  end

  def exclude_highlighting(solr_params, user_params)
    if on_home_page or on_ap_landing_page
      solr_params[:hl] = "false"
      solr_params[:rows] = 0
    end
  end

  def pivot_facet_on_ap_landing_page(solr_params, user_params)
    if on_ap_landing_page
      solr_params[:"f.result_group_ssort.facet.limit"] = "-1"
      solr_params[:"f.result_group_ssort.facet.sort"] = "index"
      solr_params[:"f.div2_ssort.facet.limit"] = "-1"
      solr_params[:"f.div2_ssort.facet.sort"] = "index"
      solr_params[:"facet.pivot"] = "result_group_ssort,div2_ssort"
    end
  end

  def title_and_exact_search
    if params["terms"] or params["exact"]
      if params["terms"]
        params[:search_field] = "title_terms"
      end
      if params["exact"]
        params[:search_field] = "exact"
      end
      if params["terms"] and params["exact"]
        params[:search_field] = "exact_title"
      end
    end
  end

  # Value will be changed via JavaScript when user changes views
  def result_view(solr_params, user_params)
    if on_images_page and params[:result_view]  == 'frequency'
      params[:result_view] = "default"
    else
      params[:result_view] = params[:result_view] || "default"
    end
  end

  # This is only used when there is no JS and is handling mapping drop-down options to f params.
  def capture_drop_down_options
    if params["search_collection"] and params["search_collection"] != "combined"
      params[:f] = {"collection_ssi" => [params["search_collection"]]}
    end
  end
  
  # used to capture and transform the parameters passed in the split button options.
  def capture_split_button_options
    unless (params.dup.keys & ["ap", "image"]).blank?
      ap = params["ap"] ? Frda::Application.config.ap_id : nil
      image = params["image"] ? Frda::Application.config.images_id : nil
      params[:f] = {"collection_ssi" => [ap || image]}
    end
    params.delete("ap")
    params.delete("image")
    params.delete("combined")
  end

  def subject_search_link opts={}
    catalog_index_path(:q => opts[:value], :f => {:collection_ssi => [Frda::Application.config.images_id]}, :exact => 1)
  end

  def search_link_from_facet_field(opts={})
    catalog_index_path(:f => {opts[:field].to_sym => [opts[:value]]})
  end
  
end 
