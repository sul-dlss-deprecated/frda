module ApplicationHelper
  
  def on_scrollspy_page?
    false
  end

  # series descriptions always come in pairs, the first in italian, the second in english...depending on tbe language, show a particular version
  def show_series_language_description(mvf,language)
    notes=[]
    mvf.each_with_index do |note,index|
      notes << note if (((index % 2) == 0 && language == :fr) || ((index % 2) == 1 && language == :en))
    end
    return notes.join('<br /><br />')
  end
  
  def show_list(mvf)
    mvf.join(', ')
  end
  
  def show_formatted_list(mvf,opts={})
    content_tag(:ul, :class => "item-mvf-list") do
      mvf.collect do |val|
        if opts[:facet]
          output=link_to(val,catalog_index_path(:"f[#{opts[:facet]}][]"=>"#{val}"))
        else
          output=val
        end
        content_tag(:li, output)
      end.join.html_safe
    end
  end

  def list_is_empty?(arry)
    if arry.all? { |element| element.blank? }
      return true
    end
  end
  
  def link_to_collection_highlight(highlight)
    link_to("#{highlight.send("name_#{I18n.locale}")}", catalog_index_path(params_for_collection_highlight(highlight)))
  end
  
  def params_for_collection_highlight(highlight)
    {:f => {blacklight_config.collection_highlight_field.to_sym => ["highlight_#{highlight.id}"]}}
  end

  # sections for About page
  # element names should match what's used in locale_about.yml
  def about_sections
    section_list = ['curator', 'project_team_stanford',
                    'project_team_bnf', 'technical_description',
                    'acknowledgements', 'use_and_reproduction']
  end

end
