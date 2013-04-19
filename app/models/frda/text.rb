class Frda::Text
  
  def highlighted?
    @speech =~ /<em>/
  end
  
  private
  
  def delimiter
    "-|-"
  end
  
  def strip_highlighting(text)
    text.gsub(/<em>|<\/em>/, "")
  end
end