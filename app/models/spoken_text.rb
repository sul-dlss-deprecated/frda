class SpokenText < Frda::Text
  attr_reader :speaker
  def initialize(solr_text)
    if solr_text =~ /#{delimiter.strip}/
      @page_id, @speaker, @text = solr_text.split(delimiter)
      process_speaker
    else
      return nil
    end
  end

  def process_speaker
    strip_speaker_anchor strip_highlighting @speaker
  end

end