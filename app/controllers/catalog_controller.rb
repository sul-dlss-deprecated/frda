# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController  

  include Blacklight::Catalog
  
  def self.collection_highlights
    opts = {}
    CollectionHighlight.find(:all,:order=>:sort_order).each do |highlight|
      opts[:"highlight_#{highlight.id}"] = {:label => highlight.send("name_#{I18n.locale}"), :fq => "id:(#{highlight.query.gsub('or', 'OR')})"}
    end
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
    
      # get all documents, iterate over those with coordinates, and build the content needed to show on the map
      # this is all fragment cached, so its only done once
      unless fragment_exist?(:controller=>'catalog',:action=>'index',:action_suffix => 'map')
        @document_locations={}
        location_facets=Blacklight.solr.get 'select',:params=>{:q=>'*:*',:rows=>0,:facet=>true,:'facet.field'=>'geographic_name_ssim'}
        location_names=location_facets['facet_counts']['facet_fields']['geographic_name_ssim']
        location_names.each_with_index do |location_name,index|
          if index % 2 == 0
            #puts "*** looking up #{location_name} with #{location_names[index+1]} numbers"
            results=Geocoder.search(location_name)
            sleep 0.1  # don't overload the geolookup API
            if results.size > 0 
              @document_locations.merge!(location_name=>{:lat=>results.first.latitude,:lon=>results.first.longitude,:count=>location_names[index+1]}) 
            end
          end
        end
      end
    end
    
    if on_collection_highlights_page
      @highlights=CollectionHighlight.order("sort_order")
    end
    
    super
    
  end
  
  configure_blacklight do |config|
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = { 
      :qt => 'standard',
      :facet => 'true',
      :rows => 10,
      :fl => "*",
      :"facet.mincount" => 1,
      :echoParams => "all"
    }
    
    
    config.collection_highlight_field = "highlight_ssim"
    
    
    # needs to be stored so we can retreive it
    # needs to be in field list for all request handlers so we can identify collections in the search results.
    config.series_identifying_field = "level_ssim"
    config.series_identifying_value = "series"
    
    config.collection_identifying_field = "format_ssim"
    config.collection_identifying_value = "Collection"
        
    # needs to be stored so we can retreive it for display.
    # needs to be in field list for all request handlers.
    config.collection_description_field = "description_tsim"
    
    # needs to be indexed so we can search it to return relationships.
    # needs to be in field list for all request handlers so we can identify collection members in the search results.
    config.children_identifying_field = "direct_parent_ssim"
    
    config.collection_member_identifying_field = "is_member_of_ssim"
    
    
    config.box_identifying_field = "box_ssim"
    config.folder_identifying_field = "folder_ssim"
    
    
    config.folder_identifier_field = "level_ssim"
    config.folder_identifier_value = "Folder"
    
    config.parent_folder_identifying_field = "parent_folder_ssim"
    
    config.folder_in_series_identifying_field = "series_ssim"
    
    # needs to be stored so we can retreive it for display
    # needs to be in field list for all request handlers
    config.collection_member_collection_title_field = "collection_ssim"
    
    config.collection_member_grid_items = 1000
    
    # needs to be stored so we can retreive it
    # needs to be in field list for all request handlers so we can get images the document anywhere in the app.
    config.image_identifier_field = "image_id_ssim"

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SolrHelper#solr_doc_params) or 
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    config.default_document_solr_params = {
     :qt => 'standard',
     :fl => '*',
     :rows => 1,
     :q => '{!raw f=id v=$id}' 
    }
    
    config.document_index_view_types = ["default", "gallery", "brief", "map"]

    # solr field configuration for search results/index views
    config.index.show_link = 'title_tsi'
    config.index.record_display_type = 'format_ssim'

    # solr field configuration for document/show views
    config.show.html_title = 'title_tsi'
    config.show.heading = 'title_tsi'
    config.show.display_type = 'format_ssim'

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
    config.add_facet_field 'personal_name_ssim', :label => I18n.t('frda.facet.personal_name'), :limit => 10
    config.add_facet_field 'geographic_name_ssim', :label => I18n.t('frda.facet.location'), :limit => 10
    config.add_facet_field 'corporate_name_ssim', :label => I18n.t('frda.facet.corporate_name'), :limit => 10
    config.add_facet_field 'family_name_ssim', :label => I18n.t('frda.facet.family_name')
    config.add_facet_field 'begin_year_itsim', :label => I18n.t('frda.facet.start_year'), :limit => 10
    config.add_facet_field 'end_year_itsim', :label => I18n.t('frda.facet.end_year'), :limit => 10

    config.add_facet_field 'highlight_ssim', :label => I18n.t('frda.nav.collections'), :show => false,  :query => collection_highlights

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
    

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields. 
    
    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params. 
      field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = { 
        :qf => '$title_qf',
        :pf => '$title_pf'
      }
    end
    
    config.add_search_field('author') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
      field.solr_local_parameters = { 
        :qf => '$author_qf',
        :pf => '$author_pf'
      }
    end
    
    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as 
    # config[:default_solr_parameters][:qt], so isn't actually neccesary. 
    config.add_search_field('subject') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
      field.qt = 'search'
      field.solr_local_parameters = { 
        :qf => '$subject_qf',
        :pf => '$subject_pf'
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


  private
  def create_guest_user
    u = User.create
    u.save
    u
  end
  
  
end 
