module FacetsHelper
  include Blacklight::FacetsHelperBehavior

  def should_render_facet? display_facet
    return false if display_facet.name == 'collection_ssi' if on_home_page
    
    facet_patterns=%w{periods_ssim highlight_ssim}
    super && !(
      facet_patterns.any? { |facet_pattern| display_facet.name.include? facet_pattern } &&
      !display_facet.name.include?(I18n.locale.to_s + "_")
    )
  end
end
