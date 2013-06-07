module SolrResponseTermFrequencies
  
  def term_frequencies
    return nil unless self.has_key?(:debug) and self[:debug].has_key?(:explain)
    frequencies = {}
    self[:debug][:explain].each do |id, explain|
      text_explain = explain.split("(MATCH)").select do |text|
        text =~ /weight\(#{text_frequency_field}:/
      end.map do |text|
        {:word => text[/\(#{text_frequency_field}:(.*)\^/, 1], :frequency => (text[/termFreq=(\d+).\d/, 1] || text[/phraseFreq=(\d+).\d/, 1])}
      end
      frequencies[id] = text_explain
    end
    frequencies
  end
  
  def text_frequency_field
    "text_tiv"
  end
  
end

Blacklight::SolrResponse.send(:include, SolrResponseTermFrequencies)