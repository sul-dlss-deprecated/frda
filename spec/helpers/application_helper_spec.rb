# -*- encoding : utf-8 -*-
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
      params[:f][:en_highlight_field].should be_a(Array)
      params[:f][:en_highlight_field].length.should == 1
      params[:f][:en_highlight_field].first.should == "highlight_1"
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
      link = link_to_volume_facet("A Volume Title", {:params => {"f" => {"some_facet" => ["A Value"]}}})
      link.should match(/^<a href=.*vol_title_ssi.*=A\+Volume\+Title.*<\/a>$/)
      link.should match(/^<a href=.*some_facet.*=A\+Value.*<\/a>$/)
    end
  end

  describe "split_ap_facet_delimiter" do
    before(:all) do
      @string = "1234-|-Session Title"
    end
    it "should return an OpenStuct object" do
      split_ap_facet_delimiter(@string).should be_a OpenStruct
    end
    it "should return the first part of the delimited string as the #id" do
      split_ap_facet_delimiter(@string).id.should == "1234"
    end
    it "should return the first second part of the delimited as the #value" do
      split_ap_facet_delimiter(@string).value.should == "Session Title"
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

  describe "determining collections in response" do

    before(:all) do
      @ap_only = [OpenStruct.new({:name => "collection_ssi",
                                 :items => [
                                   OpenStruct.new({:value => Frda::Application.config.ap_id})
                                 ]
                                }
                               )
                 ]
      @image_only = [OpenStruct.new({:name => "collection_ssi",
                                  :items => [
                                    OpenStruct.new({:value => Frda::Application.config.images_id})
                                  ]
                                 }
                                )
                    ]
      @mixed = [OpenStruct.new({:name => "collection_ssi",
                                  :items => [
                                    OpenStruct.new({:value => Frda::Application.config.ap_id}),
                                    OpenStruct.new({:value => Frda::Application.config.images_id})
                                  ]
                                 }
                                )
               ]
    end
    it "search_result_ap_only? should return true if there is only an AP value in the collection_ssi facet" do
      @response = mock('response')
      @response.stub(:facets).and_return(@ap_only)
      search_result_ap_only?.should be_true
    end
    it "search_result_images_only? should return true if there is only an Image value in the collection_ssi facet" do
      @response = mock('response')
      @response.stub(:facets).and_return(@image_only)
      search_result_images_only?.should be_true
    end
    it "search_result_mixed? should return true if there are both (or more) collection values in the collection_ssi facet" do
      @response = mock('response')
      @response.stub(:facets).and_return(@mixed)
      search_result_mixed?.should be_true
      search_result_ap_only?.should be_false
      search_result_images_only?.should be_false
    end
  end
  describe "locale switcher" do
    describe "render_locale_switcher" do
      it "should merge the params w/ the apporpirate locale" do
        helper.stub(:params).and_return({:controller => "catalog", :action => "index", :q => "query"})
        switcher = helper.send(:render_locale_switcher)
        french_link = /<a href=\"\/fr\/catalog\?q=query\">en français<\/a>/
        english_link = /<a href=\"\/en\/catalog\?q=query\">in english<\/a>/
        switcher.should match french_link
        switcher.should_not match english_link
        I18n.locale = :fr
        switcher = helper.send(:render_locale_switcher)
        switcher.should_not match french_link
        switcher.should match english_link
      end
    end
    describe "params_for_locale_switcher" do
      it "should merge the params w/ the provided locale" do
        helper.stub(:params).and_return({:q => "query", :f => {:collection => ["ABC"]}})
        params = helper.send(:params_for_locale_switcher, "en")
        params[:locale].should == "en"
        params[:q].should == "query"
        params[:f].should == {:collection => ["ABC"]}
      end
      it "should remove the result_view param" do
        helper.stub(:params).and_return({:q => "query", :result_view => "default"})
        params = helper.send(:params_for_locale_switcher, "en")
        params[:result_view].should be_nil
      end
      it "should identify when we're on the AP landing page and not try to merge the params" do
        helper.stub(:params).and_return(Rails.application.routes.named_routes.routes[:ap_collection].defaults)
        params = helper.send(:params_for_locale_switcher, "en")
        params.should == {:locale=>"en", :result_view=>nil}
      end
      it "should identify when we're on the Images landing page and not try to merge the params" do
        helper.stub(:params).and_return(Rails.application.routes.named_routes.routes[:images_collection].defaults)
        params = helper.send(:params_for_locale_switcher, "en")
        params.should == {:locale=>"en", :result_view=>nil}
      end
    end
    describe "sanitize_params_for_locale_switcher" do
      it "should return a hash with indifferent access" do
        hash = sanitize_params_for_locale_switcher({:a => "bcd"})
        hash.should be_a(HashWithIndifferentAccess)
        hash["a"].should_not be_nil
      end
      it "should remove the locale and result_view params" do
        hash = sanitize_params_for_locale_switcher({"locale" => "en", :result_view => "default"})
        hash.should == {}
      end
    end
  end
end