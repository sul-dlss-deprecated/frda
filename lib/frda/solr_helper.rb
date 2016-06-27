require 'frda/grouped_solr_response'
module Frda::SolrHelper

  def get_grouped_search_results(user_params = params || {}, extra_controller_params = {})

    merged_params = self.solr_search_params(user_params).merge(extra_controller_params.merge(group_results_params))

    response = query_solr(user_params, extra_controller_params.merge(group_results_params))
    solr_response = Frda::GroupedSolrResponse.new(force_to_utf8(response), merged_params)

    return [solr_response, solr_response.groups]
  end

  def group_results_params
    {:group => true, :"group.field" => group_result_field, :"group.limit" => 10, :"group.ngroups" => true, :debugQuery => true}
  end

  def group_result_field
    "result_group_ssi"
  end

end
