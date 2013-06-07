module CatalogHelper
  include Blacklight::CatalogHelperBehavior
  
  # Will fix this in Blacklight. We can probably remove when upgrading to the latest Blacklight release.
  def show_sort_and_per_page? response = nil
    response ||= @response
    response.total > 1
  end

  # Uncomment this to allow date searching w/o a query.
  # def has_search_parameters?
  #   !params[:q].blank? or !params[:f].blank? or !params[:search_field].blank? or !params[:"date-start"].blank? or !params[:"date-end"].blank?
  # end


  # Pass in an RSolr::Response. Displays the "showing X through Y of N" message.
  def render_pagination_info(response, options = {})
    pagination_info = paginate_params(response)
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

    case pagination_info.total_count
      when 0; t("frda.pagination_info.#{key}.no_items_found", :entry_name => entry_name.pluralize ).html_safe
      when 1; t("frda.pagination_info.#{key}.single_item_found", :entry_name => entry_name).html_safe
      else; t("frda.pagination_info.#{key}.pages", :entry_name => entry_name.pluralize, :current_page => pagination_info.current_page, :num_pages => pagination_info.num_pages, :start_num => format_num(pagination_info.start), :end_num => format_num(pagination_info.end), :total_num => pagination_info.total_count, :count => pagination_info.num_pages).html_safe
    end
  end

end
