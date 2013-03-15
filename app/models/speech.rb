class Speech
  attr_accessor :speaker, :speech
  def initialize(speech)
    if speech =~ /#{delimiter.strip}/
      @speaker = strip_highlighting(speech.split(delimiter).first)
      @speech = speech.split(delimiter).last
    else
      return nil
    end
  end
  
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