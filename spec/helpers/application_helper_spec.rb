require "spec_helper"

def blacklight_config
  OpenStruct.new(:collection_highlight_field => "highlight_field")
end

describe ApplicationHelper do
  
  describe "collection highlight linking" do
    it "params_for_collection_highlight should return the appropriate params" do
      highlight = mock('highlight')
      highlight.stub(:id).and_return("1")
      params = params_for_collection_highlight(highlight)
      params.should be_a(Hash)
      params[:f][:highlight_field].should be_a(Array)
      params[:f][:highlight_field].length.should == 1
      params[:f][:highlight_field].first.should == "highlight_1"
    end
    
    it "should link to the appropriate collection highlight" do
      highlight = mock('highlight')
      highlight.stub(:id).and_return("1")
      highlight.stub(:name_en).and_return("Highlighted Collection")
      link = link_to_collection_highlight(highlight)
      link.should =~ /^<a href=".*highlight_field.*highlight_1">Highlighted Collection<\/a>$/
    end
    
  end
  
  describe "catalog_heading linking" do
    it "should turn the array into a series of linked entries" do
      headings = ["Something", "Something Else", "Another Something"]
      links = link_to_catalog_heading(headings)
      links.length.should == 3
      headings.each do |heading|
        encoded_heading = heading.gsub(" ", '\\\+')
        links.join.should match(/<a href=.*#{encoded_heading}.*>#{heading}<\/a>/)
      end
    end
  end
  
end