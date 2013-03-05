# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
require 'frda/solr_helper'

class CatalogController < ApplicationController  

  include Blacklight::Catalog
  include Frda::SolrHelper
  
  CatalogController.solr_search_params_logic += [:add_year_range_query, :search_within_speaches, :proximity_search]
  
  before_filter :capture_split_button_options, :capture_drop_down_options, :title_and_exact_search, :only => :index
  
  def self.collection_highlights
    opts = {}
    CollectionHighlight.find(:all,:order=>:sort_order).each do |highlight|
      opts[:"highlight_#{highlight.id}"] = {:label => highlight.send("name_#{I18n.locale}"), :fq => "id:(#{highlight.query.gsub('or', 'OR')})"}
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
    
    
    extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.merge(:format => 'rss')), :title => t('blacklight.search.rss_feed') )
    extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.merge(:format => 'atom')), :title => t('blacklight.search.atom_feed') )

    (@response, @document_list) = get_grouped_search_results

    @filters = params[:f] || []

    respond_to do |format|
      format.html { save_current_search_params }
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
    download_ocr_text=params[:download_ocr_text]

    @mode=params[:mode]
    doc=Blacklight.solr.select(:params =>{:fq => "druid_ssi:\"#{druid}\" AND page_sequence_isi:\"#{page_num}\""})["response"]["docs"]
    @document=SolrDocument.new(doc.first) if doc.size > 0 # assuming we found this page

    if download_ocr_text 
      send_data(@document.page_text, :filename => "#{@document.title.parameterize}.txt")
      return
    else
      if request.xhr?
        setup_next_and_previous_documents
        render 'show_page',:format=>:js
      else
        unless @document
          flash[:alert]=t('frda.show.not_found')
          id=from_id
        else
          id=@document.id
        end
        redirect_to catalog_path(id,:mode=>@mode)
      end
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
      :echoParams => "all"
    }
    
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
    
    config.document_index_view_types = ["gallery", "list", "frequency", "default", "covers"]

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

    config.add_facet_field 'collection_ssi', :label => 'frda.nav.collection'
    config.add_facet_field 'date_issued_iim', :label => 'frda.show.year'
    config.add_facet_field 'doc_type_ssim', :label => 'frda.show.type'
    config.add_facet_field 'medium_ssi', :label => 'frda.show.medium'
    config.add_facet_field 'genre_ssim', :label => 'frda.show.genre', :limit => 10
    config.add_facet_field 'artist_ssim', :label => 'frda.show.artist', :limit => 10
    config.add_facet_field 'collector_ssim', :label => 'frda.show.collector', :limit => 10
    config.add_facet_field 'vol_title_ssi', :label => 'frda.show.volume', :show => false
    config.add_facet_field 'session_date_sim', :label => 'frda.show.session', :show => false

    config.add_facet_field 'highlight_ssim', :label => I18n.t('frda.nav.collection_highlights'), :show => false,  :query => collection_highlights

    # config.add_facet_field 'example_query_facet_field', :label => 'Publish Date', :query => {
    #    :years_5 => { :label => 'within 5 Years', :fq => "pub_date:[#{Time.now.year - 5 } TO *]" },
    #    :years_10 => { :label => 'within 10 Years', :fq => "pub_date:[#{Time.now.year - 10 } TO *]" },
    #    :years_25 => { :label => 'within 25 Years', :fq => "pub_date:[#{Time.now.year - 25 } TO *]" }
    # }


    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 

    config.add_index_field 'level_ssim', :label => "#{I18n.t('frda.show.level')}:"
    config.add_index_field 'unit_date_ssim', :label => "#{I18n.t('frda.show.date')}:"

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display 
    config.add_show_field 'level_ssim', :label => "#{I18n.t('frda.show.level')}:"
    config.add_show_field 'unit_date_ssim', :label => "#{I18n.t('frda.show.date')}:"
    config.add_show_field 'extent_ssim',  :label => "#{I18n.t('frda.show.physical_description')}:"
    config.add_show_field 'description_tsim', :label => "#{I18n.t('frda.show.notes')}:"

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
    
    config.add_search_field 'all_fields', :label => "#{I18n.t('frda.facet.all_fields')}:"
    
    config.add_search_field('title_terms') do |field|
      field.label = I18n.t('frda.facet.title')
      field.solr_local_parameters = {
        :qf => '$qf_title',
        :pf => '$pf_title'
      }
    end
    
    config.add_search_field('exact') do |field|
      field.label = I18n.t('frda.facet.exact')
      field.solr_local_parameters = {
        :qf => '$qf_exact',
        :pf => '$pf_exact'
      }
    end
    
    config.add_search_field('exact_title') do |field|
      field.label = I18n.t('frda.facet.exact_title')
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

  private
  def create_guest_user
    u = User.create
    u.save
    u
  end
  
  def add_year_range_query(solr_params, user_params)
    if user_params["dates"] and (!user_params["date-start"].blank? and !user_params["date-end"].blank?)
      if solr_params[:fq]
        solr_params[:fq] << "date_issued_ssim:[#{user_params['date-start']} TO #{user_params['date-end']}]"
      else
        solr_params[:fq] = ["date_issued_ssim:[#{user_params['date-start']} TO #{user_params['date-end']}]"]
      end
    end
  end
  
  def search_within_speaches(solr_params, user_params)
    unless user_params["speeches"].blank? and user_params["by-speaker"].blank?
      solr_params[:q] = "\"#{user_params['by-speaker']} #{user_params['q']}\""
      solr_params[:qs] = 10000
    end
  end
  
  def proximity_search(solr_params, user_params)
    if user_params["prox"] and !user_params["words"].blank?
      solr_params[:q] = "\"#{user_params["q"].gsub('"', '')}\""
      solr_params[:qs] = user_params["words"]
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
  
  
end 
