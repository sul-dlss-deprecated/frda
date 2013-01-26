module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior
  
  def render_index_field_label args
    field = args[:field]
    html_escape("#{t(index_fields[field].label)}:")
  end
  
end