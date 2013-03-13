class Speech
  attr_accessor :speaker, :speech
  def initialize(speech)
    if speech =~ /#{delimiter.strip}/
      @speaker = strip_highlighting(speech.split(delimiter).first)
      @speech = speech.split(delimiter).last
    else
      speech[/^(\w*\S* \w*\S*) (.*)$/]
      if $1.nil? or $2.nil?
        speech[/^(\w*\S*) (.*)$/]
      end
      @speaker, @speech = [strip_highlighting($1.strip), $2.strip]
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