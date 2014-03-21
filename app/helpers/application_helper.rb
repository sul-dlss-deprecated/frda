# -*- encoding : utf-8 -*-
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

  # element == MODS nodeset
  def show_mods_element_as_list(doc, element)
    content_tag(:ul, :class => "item-mvf-list #{element}") do
      case element
      when :note
        nodeset = doc.mods.note
        nodeset.collect do |n|
          concat content_tag(:li, n.text)
        end
      when :creator
        nodeset = doc.mods.plain_name
        nodeset.collect do |n|
          # convert marcrelator term to human-friendly label
          rlabel = mods_creator_role_to_label(n.role.text)
          # should have error handling if any value happens to be nil?
          content_tag(:li) do
            link_to("#{n.display_value}", catalog_index_path(:q => "\"#{n.display_value}\"")) +
            " (#{n.date.text}), #{rlabel}"
          end
        end.join.html_safe
      when :publication
        nodeset = doc.mods.origin_info
        place = mods_element_publication_place(doc)
        date_issued = mods_element_dateIssued(doc)
        # quick attempt at error handling if any value happens to be nil
        # I'm sure this could be done better...
        str = ""
        str += "#{place} : " unless place.nil?
        str += "#{nodeset.publisher.text}" unless nodeset.publisher.text.nil?
        str += "#{date_issued}" unless date_issued.nil?
        content_tag(:li) do
          str
        end
      when :subject
        subjects = mods_element_subject(doc)
        subjects.collect do |n|
          content_tag(:li) do
            "#{n}"
          end
        end.join.html_safe
      end # case
    end # content_tag :ul
  end

  def show_mods_artist(doc)
    artists = []
    nodeset = doc.mods.plain_name
    nodeset.collect do |n|
      if ["art", "drm", "egr", "ill", "scl"].include? n.role.text.strip
        artists << n.display_value
      end
    end
    if artists.empty?
      artists = ["Unattributed"]
    end
    return artists.uniq
  end

  def list_is_empty?(arry)
    return true if arry.nil?
    if arry.all? { |element| element.blank? }
      return true
    end
  end

  def truncate_highlight(text, options={})
    unless (text.include?("<em>") and text.include?("</em>"))
      options[:length] = text.length unless options[:length]
      return [truncate(text, options)]
    end
    options[:omission] ||= "..."

    opens  = text.enum_for(:scan, /<em>/  ).map{ Regexp.last_match.begin(0) }
    closes = text.enum_for(:scan, /<\/em>/).map{ Regexp.last_match.begin(0) }

    gap = options[:around] || 0
    instances = []
    closes.length.times do |i|
      open_tag  = opens[i]
      close_tag = (closes[i] + 5)
      instances << OpenStruct.new(:open  => open_tag,
                                  :close => close_tag,
                                  :text  => text[open_tag...close_tag])
    end
    inst_buffer = []
    snippets = []
    instances.each_with_index do |instance, index|
      next_open = instances[index+1] ? instances[index+1].open : instances.last.open
      if ((next_open - instance.close) < ((gap * 2) + 10))
        inst_buffer << instance
      else
        if inst_buffer.blank?
          snippets << generate_snippet(text, gap, instance.open, instance.close, options[:omission])
        else
          inst_buffer << instance
          snippets << generate_snippet(text, gap, inst_buffer.first.open, inst_buffer.last.close, options[:omission])
        end
        inst_buffer = []
      end
      if ((index+1) == instances.length) && !inst_buffer.blank?
        snippets << generate_snippet(text, gap, inst_buffer.first.open, inst_buffer.last.close, options[:omission])
      end
    end
    snippets
  end

  def generate_snippet(str, gap, open, close, omission)
    open_with_gap = open - gap
    open_with_gap = 0 if open_with_gap < 0
    "#{omission if open_with_gap > 0 }#{str[(open_with_gap)...(close+gap)]}#{omission if (close+gap) < str.length}"
  end

  def highlight_text(doc, field)
    doc.highlight_field(field) ? doc.highlight_field(field).first : doc[field]
  end

  def link_to_collection_highlight(highlight)
    link_to("#{highlight.send("name_#{I18n.locale}")}", catalog_index_path(params_for_collection_highlight(highlight)))
  end

  def params_for_collection_highlight(highlight)
    {:f => {"#{I18n.locale}_#{blacklight_config.collection_highlight_field}".to_sym => ["highlight_#{highlight.id}"]}}
  end

  def params_for_volume_or_image(volume)
    if volume == Frda::Application.config.images_id
      {"f" => {"collection_ssi" => [volume]}}
    else
      {"f" => {"vol_title_ssi" => [volume]}}
    end
  end

  def contextual_118n_key_for_pages(group)
    if group == Frda::Application.config.images_id
      "frda.search.image"
    else
      "frda.search.occurrence"
    end
  end

  def params_for_session(session)
    {:f => {:session_title_sim => [session]}}
  end

  def params_for_volume(volume)
    {:f => {:vol_title_ssi => [volume]}}
  end

  # get just the '11' part of a complete volume name ('Tome 11 : blah blah')
  def volume_title_number(volume)
    volume_title = params[:f][:vol_title_ssi]
    volume_number = volume_title[0].match(/^(\D+)(\d+)\s:/)
    return volume_number[2]
  end

  # sections for About page
  # elementlink names should match what's used in locale_about.yml
  def about_sections
    section_list = ['curator', 'project_team_stanford',
                    'project_team_bnf',
                    'acknowledgements', 'use_and_reproduction']
  end

  # Create links for search result view icon links
  def search_result_view_switch(icon, view_name)
    if view_name == params[:result_view]
      view_state = 'active'
    end

    link_to("<i class=#{icon}></i>".html_safe, "##{view_name}",
      :data => {view: "#{view_name}"},
      :alt => "#{view_name.titlecase} view of results",
      :title => "#{view_name.titlecase} view of results",
      :class => "#{view_state}",
      :id => "result_view_#{view_name}")
  end

  # This can be used to link the group heading in search results
  # We don't really have this ID naming convention in Image so it won't work there.
  def link_to_tome_from_search_result(text, id, options={})
    link_to(text, catalog_path("#{id}_00_0001"), options)
  end

  def link_to_volume_facet(volume, options={})
    link_params = {}
    link_params.merge!(options[:params]) if options[:params]
    link_params["page"] = nil
    volume_facet_params = params_for_volume_or_image(volume)
    options.delete(:params)
    if options[:count]
      link_to(t('frda.search.view_all'), catalog_index_path(link_params.deep_merge(volume_facet_params)), options)
    else
      link_to(volume, catalog_index_path(link_params.deep_merge(volume_facet_params)), options)
    end
  end

  def link_to_session_facet(session, options={})
    link_params = {}
    link_params.merge!(options[:params]) if options[:params]
    session_facet_params = {"f" => {"session_title_si" => [session]}}
    options.delete(:params)
    link_to(session, catalog_index_path(link_params.deep_merge(session_facet_params)), options)
  end

  def link_to_catalog_heading(heading)
    buffer = []
    heading.map do |head|
      buffer << head
      link_to(head, catalog_index_path(:q => "\"#{buffer.join(' ')}\""))
    end
  end

  def link_for_catalog_heading_search(string)
    if I18n.locale == :fr
      lang = "catalog_heading_ftsimv"
    else
      lang = "catalog_heading_etsimv"
    end
    link_to(string, catalog_index_path( :q  => "#{string}",
                                        :fl => "#{lang}",
                                        :f  => {:collection_ssi=>[Frda::Application.config.images_id]}))
  end

  def frda_search_collection_options
    [[t('frda.search.results_heading_combined'), "combined"],
     [t('frda.search.results_heading_ap'), Frda::Application.config.ap_id],
     [t('frda.search.results_heading_image'), Frda::Application.config.images_id]
    ]
  end

  def frda_search_omit_keys
    [:q, :search_field, :qt, :page, :dates, :"date-start", :"date-end", :speeches, :"by-speaker", :prox, :words, :terms, :exact, :search_collection]
  end

  def link_to_images_item_source(doc)
    if doc.mods.related_item.location.url.attr("displayLabel").value.blank?
      display_label = doc.mods.related_item.location.url.text
    else
      display_label = doc.mods.related_item.location.url.attr("displayLabel").value
    end
      link_to(display_label, doc.mods.related_item.location.url.text)
  end

  # Creates Images item title from mods title and mods subTitle, with " : " between them
  def mods_combined_title(doc)
    title = doc.mods.title_info.title.text
    subtitle = doc.mods.title_info.subTitle.text
    unless title.blank?
      combined_title = title
      unless subtitle.blank?
        combined_title << " : #{subtitle}"
      end
      return combined_title
    end
  end

  # Check to see if the mods element 'dateIssued', without "encoding = 'marc'", exits
  def mods_element_dateIssued_present?(doc)
    if doc.mods.origin_info.dateIssued.find {|n| n.attr("encoding") != 'marc'}.present?
      return true
    end
  end

  # Get the mods element 'dateIssued' where it is the dateIssued elment without "encoding = 'marc'"
  def mods_element_dateIssued(doc)
    doc.mods.origin_info.dateIssued.find {|n| n.attr("encoding") != 'marc'}.text
  end

  # Get the mods element 'placeTerm' where it is the placeTerm elment with "type = 'text'"
  def mods_element_publication_place(doc)
    doc.mods.origin_info.place.placeTerm.find {|n| n.attr("type") == 'text'}.text
  end

  def mods_element_note(doc)
    doc.mods.origin_info.note.find {|n| n.attr("encoding") != 'marc'}.text
  end
  
  def mods_creator_role_to_label(role)
    case role.strip
    when "art"
      rlabel = "Artist"
    when "col"
      rlabel = "Collector"
    when "dnr"
      rlabel = "Donor"
    when "drm"
      rlabel = "Draftsman"
    when "egr"
      rlabel = "Engraver"
    when "ill"
      rlabel = "Illustrator"
    when "pbl"
      rlabel = "Publisher"
    when "scl"
      rlabel = "Sculptor"
    else
      rlabel = ""
    end
    return rlabel
  end

  def mods_element_subject(doc)
    subjects = []
    doc.mods.subject.each do |subj|
      # don't want: doc.mods.subject.displayLabel == 'Catalog heading'
      if subj.topic && subj.displayLabel != 'Catalog heading'
        subj.topic.each do |t|
          subjects << t.text if !subj.topic.empty?
        end
      end
      # don't want: doc.mods.subject.name_el.type_at == 'personal'
      if subj.name_el && subj.name_el.type_at != 'personal'
        subjects << subj.name_el.namePart.text if !subj.name_el.namePart.text.empty?
      end
    end
    return subjects
  end

  def split_ap_facet_delimiter(string)
    OpenStruct.new(:id => string.split("-|-")[0], :value => string.split("-|-")[1])
  end

  def response_includes_ap?(response)
    response[:facet_counts][:facet_fields][:collection_ssi].any? { |c| c == 'Archives parlementaires' }
  end

  def search_result_ap_only?(response = @response)
    response.facets.select do |facet|
      facet.name == "collection_ssi"
    end.first.items.all? do |item|
      item.value == Frda::Application.config.ap_id
    end
  end

  def search_result_images_only?(response = @response)
    response.facets.select do |facet|
      facet.name == "collection_ssi"
    end.first.items.all? do |item|
      item.value == Frda::Application.config.images_id
    end
  end

  def search_result_mixed?(response = @response)
    (!search_result_ap_only?(response) and !search_result_images_only?(response))
  end

  def render_locale_class
    "lang-#{I18n.locale}"
  end

  def render_locale_switcher
    <<-HTML
      <div class='language-toggle'>
        #{link_to_if(I18n.locale == :fr, "in english",  params_for_locale_switcher("en"))}
        |
        #{link_to_if(I18n.locale == :en, "en français", params_for_locale_switcher("fr"))}
      </div>
    HTML
  end
  def params_for_locale_switcher(locale)
    locale_params = {:locale => locale, :result_view => nil}
    user_params = sanitize_params_for_locale_switcher(params)
    ap_params = sanitize_params_for_locale_switcher(Rails.application.routes.named_routes.routes[:ap_collection].defaults)
    images_params = sanitize_params_for_locale_switcher(Rails.application.routes.named_routes.routes[:images_collection].defaults)
    if [ap_params, images_params].include?(user_params)
      locale_params
    else
      params.merge(locale_params)
    end
  end
  def sanitize_params_for_locale_switcher(p)
    hwia = HashWithIndifferentAccess.new(p.clone)
    hwia.delete(:locale)
    hwia.delete(:result_view)
    hwia
  end
end
