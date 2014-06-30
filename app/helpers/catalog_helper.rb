module CatalogHelper
  include Blacklight::CatalogHelperBehavior

  # Uncomment this to allow date searching w/o a query.
  # def has_search_parameters?
  #   !params[:q].blank? or !params[:f].blank? or !params[:search_field].blank? or !params[:"date-start"].blank? or !params[:"date-end"].blank?
  # end


  # Pass in an RSolr::Response. Displays the "showing X through Y of N" message.
  def render_pagination_info(response, options = {})
    key = case
      when search_result_mixed?(response)
        "mixed"
      when search_result_ap_only?(response)
        "ap_only"
      when search_result_images_only?(response)
        "images_only"
      else
        "search"
    end

    key << ".flat" unless response.is_a?(Frda::GroupedSolrResponse)

    # TODO: i18n the entry_name
    entry_name = options[:entry_name]
    entry_name ||= response.docs.first.class.name.underscore.sub('_', ' ') unless response.docs.empty?
    entry_name ||= t('blacklight.entry_name.default')

    # grouped response objects need special handling
    end_num = if response.is_a? Frda::GroupedSolrResponse
      response.groups.length
    else
      response.limit_value
    end

    end_num = if response.offset_value + end_num <= response.total_count
      response.offset_value + end_num
    else
      response.total_count
    end

    case response.total_count
      when 0; t("frda.pagination_info.#{key}.no_items_found", :entry_name => entry_name.pluralize ).html_safe
      when 1; t("frda.pagination_info.#{key}.single_item_found", :entry_name => entry_name).html_safe
      else; t("frda.pagination_info.#{key}.pages", :entry_name => entry_name.pluralize, :current_page => response.current_page, :num_pages => response.num_pages, :start_num => number_with_delimiter(response.offset_value + 1), :end_num => number_with_delimiter(end_num), :total_num => response.total_count, :count => response.num_pages).html_safe
    end
  end

end
