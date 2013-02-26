module CatalogHelper
  include Blacklight::CatalogHelperBehavior
  
  # Will fix this in Blacklight. We can probably remove when upgrading to the latest Blacklight release.
  def show_sort_and_per_page? response = nil
    response ||= @response
    response.total > 1
  end
end
