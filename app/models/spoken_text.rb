class SpokenText < Frda::Text
  attr_reader :speaker
  def initialize(solr_text)
    if solr_text =~ /#{delimiter.strip}/
      split_text = solr_text.split(delimiter)
      @page_id = split_text[0]
      @speaker = strip_highlighting(split_text[1])
      @text  = split_text[2]
    else
      return nil
    end
  end
  
end