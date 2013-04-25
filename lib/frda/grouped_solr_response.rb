require "blacklight/mash" unless defined?(Mash)
require "solr_response_term_frequencies"

class Frda::GroupedSolrResponse < Mash
  
  include SolrResponseTermFrequencies

  attr_reader :request_params
  def initialize(data, request_params)
    super(data)
    @request_params = request_params
    
    extend Blacklight::SolrResponse::Facets
  end

  class SolrGroup
    attr_reader :group, :total, :start, :docs
    def initialize group, total, start, docs, response
      @group = group
      @total = total
      @start = start
      @docs = docs.map{|doc| SolrDocument.new(doc, response) }
    end
  end

  def response
    self[:grouped]
  end

  def total
    group_element["ngroups"].to_s.to_i
  end

  def total_docs
    group_element["matches"].to_s.to_i
  end

  def docs
    groups
  end

  def start
    params["start"].to_s.to_i
  end

  def header
    self['responseHeader']
  end
  
  def params
    (header and header['params']) ? header['params'] : request_params
  end

  def rows
    # better way to get rows?  params['rows'] seems to be an array sometimes.
    [request_params["rows"], params["rows"]].flatten.delete_if{|r| r.to_i == 0}.first.to_s.to_i
  end

  def groups
    @groups ||= group_element["groups"].map do |group|
      SolrGroup.new(group["groupValue"], group["doclist"]["numFound"], group["doclist"]["start"], group["doclist"]["docs"], self) 
    end
  end

  # Abstract the group element from different RSolr response formats
  def group_element
    if response.is_a?(Array)
      return response[1]
    else
      return response[grouping_field]
    end
  end

  def grouping_field
    "result_group_ssi"
  end

end