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

end
