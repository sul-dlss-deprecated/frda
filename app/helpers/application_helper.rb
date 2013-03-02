module ApplicationHelper

  def on_scrollspy_page?
    on_about_pages
  end

  # take in a hash of options for the contact us form, and then pass the values of the hash through the translation engine
  def translate_options(options)
    result={}
    options.each {|k,v| result.merge!({k=>I18n.t(v)})}
    return result
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
    mvf.reject!{|v| v.blank?}
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

  def params_for_volume(volume)
    {:f => {:vol_title_ssi => [volume]}}
  end
  
  def params_for_session(session)
    {:f => {:session_date_sim => [session]}}
  end

  # sections for About page
  # element names should match what's used in locale_about.yml
  def about_sections
    section_list = ['curator', 'project_team_stanford',
                    'project_team_bnf', 'technical_description',
                    'acknowledgements', 'use_and_reproduction']
  end

  def link_to_search_result_view(icon, view_name, default_view)
    if default_view
      (params[:view] == "#{view_name}" or params[:view].nil?) ? view_state = 'active' : view_state = ''
    else
      params[:view] == "#{view_name}" ? view_state = 'active' : view_state = ''
    end

    link_to("<i class=#{icon}></i>".html_safe,
      catalog_index_path(params.merge(:view => "#{view_name}")),
      :alt => "#{view_name.titlecase} view of results",
      :title => "#{view_name.titlecase} view of results",
      :class => "#{view_state}")
  end
  
  # This can be used to link the group heading in search results
  # We don't really have this ID naming convention in Image so it won't work there.
  def link_to_tome_from_search_result(text, id, options={})
    link_to(text, catalog_path("#{id}_00_0001"), options)
  end

  def link_to_catalog_heading(heading)
    buffer = []
    heading.map do |head|
      buffer << head
      link_to(head, catalog_index_path(:q => "\"#{buffer.join(' ')}\""))
    end
  end
  
  def frda_search_omit_keys
    [:q, :search_field, :qt, :page, :dates, :"date-start", :"date-end", :speeches, :"by-speaker", :prox, :words, :terms, :exact]
  end

end
