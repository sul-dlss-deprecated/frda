class UnspokenText < Frda::Text
  def initialize(solr_text)
    if solr_text =~ /#{delimiter.strip}/
      split_text = solr_text.split(delimiter)
      @page_id = split_text.first
      @text = split_text.last
    else
      return nil
    end
  end

end