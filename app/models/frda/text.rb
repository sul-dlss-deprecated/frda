class Frda::Text
  attr_reader :page_id, :text
  def highlighted?
    @text.include?("<em>")
  end
  
  private
  
  def delimiter
    "-|-"
  end
  
  def strip_highlighting(solr_text)
    solr_text.gsub(/<em>|<\/em>/, "")
  end
end