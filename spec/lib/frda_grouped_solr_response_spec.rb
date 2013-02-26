require "spec_helper"

describe Frda::GroupedSolrResponse do
  
  describe "groups" do
    it "shuold return an array of SolrGroups" do
      response = create_response(grouped_response)
      response.groups.should be_a Array
      response.groups.length.should be 2
      response.groups.each do |group|
        group.should be_a Frda::GroupedSolrResponse::SolrGroup
      end
    end
    it "should include a list of SolrDocuments" do
      response = create_response(grouped_response)
      response.groups.each do |group|
        group.docs.each do |doc|
          doc.should be_a SolrDocument
        end
      end
    end
  end
  
  describe "total" do
    it "should return the ngroups value" do
      create_response(grouped_response).total.should == 3
    end
  end
  
  describe "facets" do
    it "should exist in the response object (not testing, we just extend the module)" do
      create_response(grouped_response).should respond_to :facets
    end
  end
  
  describe "rows" do
    it "should get the rows in the header params if they are not in the request params" do
      response = create_response(grouped_response)
      response.rows.should be 3
    end
    it "should get the rows if they are available in the request params" do
      response = create_response(grouped_response, {"rows" => 5})
      response.rows.should be 5
    end
    it "should be able to handle params arrays" do
      response = create_response(grouped_response, {"rows" => ["0", "10"]})
      response.rows.should be 10
    end
  end
end

def create_response(response, params = {})
  Frda::GroupedSolrResponse.new(response, params)
end

def grouped_response
  {"responseHeader" => {"params" =>{"rows" => 3}},
   "grouped" => 
     {'vol_title_ssi' => 
       {'groups' => [{'groupValue'=>"Group 1", 'doclist'=>{'numFound'=>2, 'docs'=>[{:id=>1}]}},
                     {'groupValue'=>"Group 2", 'doclist'=>{'numFound'=>3, 'docs'=>[{:id=>2}, :id=>3]}}
                    ],
        'ngroups' => "3"
       }
     }
  }
end