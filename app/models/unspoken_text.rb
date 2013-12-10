class UnspokenText < Frda::Text
  def initialize(solr_text)
    if solr_text =~ /#{delimiter.strip}/
      @page_id, @text = solr_text.split(delimiter)
    else
      return nil
    end
  end

end