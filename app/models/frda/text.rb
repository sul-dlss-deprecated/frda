class Frda::Text
  attr_reader :page_id, :text
  def highlighted?
    @text.include?("<em>")
  end
  
  private
  
  def delimiter
    "-|-"
  end
  
  def strip_highlighting solr_text
    solr_text.gsub!(/<em>|<\/em>/, "") || solr_text
  end

  def strip_speaker_anchor text
    text.gsub!(/^a{3}|z{3}$/, "") || text
  end
end