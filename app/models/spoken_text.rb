class SpokenText < Frda::Text
  attr_accessor :page_id, :speaker, :speech
  def initialize(speech)
    if speech =~ /#{delimiter.strip}/
      split_speech = speech.split(delimiter)
      @page_id = split_speech[0]
      @speaker = strip_highlighting(split_speech[1])
      @speech  = split_speech[2]
    else
      return nil
    end
  end
  
end