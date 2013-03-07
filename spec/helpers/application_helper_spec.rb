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
  
  describe "link_to_volume_facet" do
    it "should link to the volume text passed" do
      link_to_volume_facet("A Volume Title").should match(/^<a href=.*>A Volume Title<\/a>$/)
    end
    it "should link to the volume facet" do
      link_to_volume_facet("A Volume Title").should match(/^<a href=.*vol_title_ssi.*=A\+Volume\+Title.*<\/a>$/)
    end
    it "should pass non-params options along to link_to" do
      link_to_volume_facet("A Volume Title", :class => "some-class").should match(/^<a.*class="some-class".*<\/a>$/)
    end
    it "should merge the params if sent through the options" do
      link = link_to_volume_facet("A Volume Title", {:params => {:q => "Hello"}})
      link.should match(/^<a href=.*vol_title_ssi.*=A\+Volume\+Title.*<\/a>$/)
      link.should match(/^<a href=.*q=Hello.*<\/a>$/)
    end
    it "should deep merge faceting" do
      link = link_to_volume_facet("A Volume Title", {:params => {:f => {:some_facet => ["A Value"]}}})
      link.should match(/^<a href=.*vol_title_ssi.*=A\+Volume\+Title.*<\/a>$/)
      link.should match(/^<a href=.*some_facet.*=A\+Value.*<\/a>$/)
    end
  end
  
  describe "truncate_hightlight" do
    before(:all) do
      @no_highlight = "Hello, this is a string that does not have any highlighting."
      @single_highlight = "Hello, <em>this string</em> has a single highlight in it."
      @multi_highlights = "Hello, <em>this string</em> has <em>multiple</em> highlights in it."
    end
    it "should preserve fields w/o highlighting" do
      truncate_highlight(@no_highlight).should == @no_highlight
    end
    it "should send on the parameters to truncate for non highlighted text" do
      truncate_highlight(@no_highlight, :length => 8).should == "Hello..."
    end
    it "should truncate around the first and last em if no options are passed" do
      truncate_highlight(@single_highlight).should == "...<em>this string</em>..."
      truncate_highlight(@multi_highlights).should == "...<em>this string</em> has <em>multiple</em>..."
    end
    it "should grab the requested number of characters before the highlighting" do
      truncate_highlight(@single_highlight, :before => 3).should == "...o, <em>this string</em>..."
      truncate_highlight(@multi_highlights, :before => 3).should == "...o, <em>this string</em> has <em>multiple</em>..."
    end
    it "should grab the requested number of characters after the highlighting" do
      truncate_highlight(@single_highlight, :after => 3).should == "...<em>this string</em> ha..."
      truncate_highlight(@multi_highlights, :after => 3).should == "...<em>this string</em> has <em>multiple</em> hi..."
    end
    it "should grab the requested number of characters around the highlighting" do
      truncate_highlight(@single_highlight, :around => 3).should == "...o, <em>this string</em> ha..."
      truncate_highlight(@multi_highlights, :around => 3).should == "...o, <em>this string</em> has <em>multiple</em> hi..."
    end
  end

end