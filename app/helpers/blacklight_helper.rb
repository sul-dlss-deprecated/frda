module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior

  # link_back_to_catalog(:label=>'Back to Search')
  # Create a link back to the index screen, keeping the user's facet, query and paging choices intact by using session.
  def link_back_to_catalog(opts={:label=>nil})
    query_params = current_search_session.try(:query_params) || {}
    query_params.delete :counter
    query_params.delete :total
    link_url = url_for(query_params)
    if link_url =~ /bookmarks/
      opts[:label] ||= t('blacklight.back_to_bookmarks')
    end

    if query_params[:q]
      opts[:label] ||= t('blacklight.back_to_search').html_safe + " (#{query_params[:q]})"
    else
      opts[:label] ||= t('blacklight.back_to_search').html_safe
    end

    link_to opts[:label], link_url
  end

end
