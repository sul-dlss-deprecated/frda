# -*- encoding : utf-8 -*-
require "spec_helper"

def blacklight_config
  OpenStruct.new(:collection_highlight_field => "highlight_field")
end

describe ApplicationHelper do

  describe "collection highlight linking" do
    it "params_for_collection_highlight should return the appropriate params" do
      highlight = double('highlight')
      allow(highlight).to receive(:id).and_return("1")
      params = params_for_collection_highlight(highlight)
      expect(params).to be_a(Hash)
      field = params[:f][:en_highlight_field] || params[:f][:fr_highlight_field]
      expect(field).to be_a(Array)
      expect(field.length).to eq(1)
      expect(field.first).to eq("highlight_1")
    end

    it "should link to the appropriate collection highlight" do
      highlight = double('highlight')
      allow(highlight).to receive(:id).and_return("1")
      allow(highlight).to receive(:name_en).and_return("Highlighted Collection")
      allow(highlight).to receive(:name_fr).and_return("Highlighted Collection")
      link = link_to_collection_highlight(highlight)
      expect(link).to match(/^<a href=".*highlight_field.*highlight_1">Highlighted Collection<\/a>$/)
    end
  end

  describe "catalog_heading linking" do
    it "should turn the array into a series of linked entries" do
      headings = ["Something", "Something Else", "Another Something"]
      links = link_to_catalog_heading(headings)
      expect(links.length).to eq(3)
      headings.each do |heading|
        encoded_heading = heading.gsub(" ", '\\\+')
        expect(links.join).to match(/<a href=.*#{encoded_heading}.*>#{heading}<\/a>/)
      end
    end
  end

  describe "link_to_volume_facet" do
    it "should link to the volume text passed" do
      expect(link_to_volume_facet("A Volume Title")).to match(/^<a href=.*>A Volume Title<\/a>$/)
    end
    it "should link to the volume facet" do
      expect(link_to_volume_facet("A Volume Title")).to match(/^<a href=.*vol_title_ssi.*=A\+Volume\+Title.*<\/a>$/)
    end
    it "should pass non-params options along to link_to" do
      expect(link_to_volume_facet("A Volume Title", :class => "some-class")).to match(/^<a.*class="some-class".*<\/a>$/)
    end
    it "should merge the params if sent through the options" do
      link = link_to_volume_facet("A Volume Title", {:params => {:q => "Hello"}})
      expect(link).to match(/^<a href=.*vol_title_ssi.*=A\+Volume\+Title.*<\/a>$/)
      expect(link).to match(/^<a href=.*q=Hello.*<\/a>$/)
    end
    it "should deep merge faceting" do
      link = link_to_volume_facet("A Volume Title", {:params => {"f" => {"some_facet" => ["A Value"]}}})
      expect(link).to match(/^<a href=.*vol_title_ssi.*=A\+Volume\+Title.*<\/a>$/)
      expect(link).to match(/^<a href=.*some_facet.*=A\+Value.*<\/a>$/)
    end
  end

  describe "split_ap_facet_delimiter" do
    before(:all) do
      @string = "1234-|-Session Title"
    end
    it "should return an OpenStuct object" do
      expect(split_ap_facet_delimiter(@string)).to be_a OpenStruct
    end
    it "should return the first part of the delimited string as the #id" do
      expect(split_ap_facet_delimiter(@string).id).to eq("1234")
    end
    it "should return the first second part of the delimited as the #value" do
      expect(split_ap_facet_delimiter(@string).value).to eq("Session Title")
    end
  end

  describe "truncate_hightlight" do
    before(:all) do
      @no_highlight = "Hello, this is a string that does not have any highlighting."
      @single_highlight = "Hello, <em>this string</em> has a single highlight in it."
      @multi_highlights = "Hello, <em>this string</em> has <em>multiple</em> highlights in it."
      @long_highlight = "Lorem <em>ipsum</em> dolor sit amet, consectetur <em>adipiscing</em> elit. Sed sed euismod quam."
    end
    it "should preserve fields w/o highlighting" do
      expect(truncate_highlight(@no_highlight)).to eq([@no_highlight])
    end
    it "should send on the parameters to truncate for non highlighted text" do
      expect(truncate_highlight(@no_highlight, :length => 8)).to eq(["Hello..."])
    end
    it "should truncate around the first and last em if no options are passed" do
      expect(truncate_highlight(@single_highlight)).to eq(["...<em>this string</em>..."])
      expect(truncate_highlight(@multi_highlights)).to eq(["...<em>this string</em> has <em>multiple</em>..."])
    end
    it "should grab the requested number of characters around the highlighting" do
      expect(truncate_highlight(@single_highlight, :around => 3)).to eq(["...o, <em>this string</em> ha..."])
      expect(truncate_highlight(@multi_highlights, :around => 3)).to eq(["...o, <em>this string</em> has <em>multiple</em> hi..."])
    end
    it "should combine highlighting that is w/i the gap*2 (and then some)" do
      expect(truncate_highlight(@long_highlight, :around => 2 )).to eq(["...m <em>ipsum</em> d...", "...r <em>adipiscing</em> e..."])
      expect(truncate_highlight(@long_highlight, :around => 10)).to eq(["Lorem <em>ipsum</em> dolor sit amet, consectetur <em>adipiscing</em> elit. Sed..."])
    end
    it "should not add the ommission characters when we're not truncating a part of the string" do
      expect(truncate_highlight(@single_highlight, :around => 100)).to eq([@single_highlight])
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
      @response = double('response')
      allow(@response).to receive(:facets).and_return(@ap_only)
      expect(search_result_ap_only?).to be_truthy
    end
    it "search_result_images_only? should return true if there is only an Image value in the collection_ssi facet" do
      @response = double('response')
      allow(@response).to receive(:facets).and_return(@image_only)
      expect(search_result_images_only?).to be_truthy
    end
    it "search_result_mixed? should return true if there are both (or more) collection values in the collection_ssi facet" do
      @response = double('response')
      allow(@response).to receive(:facets).and_return(@mixed)
      expect(search_result_mixed?).to be_truthy
      expect(search_result_ap_only?).to be_falsey
      expect(search_result_images_only?).to be_falsey
    end
  end
  describe "locale switcher" do
    describe "render_locale_switcher" do
      it "should merge the params w/ the apporpirate locale" do
        allow(helper).to receive(:params).and_return({:controller => "catalog", :action => "index", :q => "query"})
        switcher = helper.send(:render_locale_switcher)
        french_link = /<a href=\"\/fr\/catalog\?q=query\">en français<\/a>/
        english_link = /<a href=\"\/en\/catalog\?q=query\">in english<\/a>/
        expect(switcher).to match french_link
        expect(switcher).not_to match english_link
        I18n.locale = :fr
        switcher = helper.send(:render_locale_switcher)
        expect(switcher).not_to match french_link
        expect(switcher).to match english_link
      end
    end
    describe "params_for_locale_switcher" do
      it "should merge the params w/ the provided locale" do
        allow(helper).to receive(:params).and_return({:q => "query", :f => {:collection => ["ABC"]}})
        params = helper.send(:params_for_locale_switcher, "en")
        expect(params[:locale]).to eq("en")
        expect(params[:q]).to eq("query")
        expect(params[:f]).to eq({:collection => ["ABC"]})
      end
      it "should remove the result_view param" do
        allow(helper).to receive(:params).and_return({:q => "query", :result_view => "default"})
        params = helper.send(:params_for_locale_switcher, "en")
        expect(params[:result_view]).to be_nil
      end
      it "should identify when we're on the AP landing page and not try to merge the params" do
        allow(helper).to receive(:params).and_return(Rails.application.routes.named_routes.routes[:ap_collection].defaults)
        params = helper.send(:params_for_locale_switcher, "en")
        expect(params).to eq({:locale=>"en", :result_view=>nil})
      end
      it "should identify when we're on the Images landing page and not try to merge the params" do
        allow(helper).to receive(:params).and_return(Rails.application.routes.named_routes.routes[:images_collection].defaults)
        params = helper.send(:params_for_locale_switcher, "en")
        expect(params).to eq({:locale=>"en", :result_view=>nil})
      end
    end
    describe "sanitize_params_for_locale_switcher" do
      it "should return a hash with indifferent access" do
        hash = sanitize_params_for_locale_switcher({:a => "bcd"})
        expect(hash).to be_a(HashWithIndifferentAccess)
        expect(hash["a"]).not_to be_nil
      end
      it "should remove the locale and result_view params" do
        hash = sanitize_params_for_locale_switcher({"locale" => "en", :result_view => "default"})
        expect(hash).to eq({})
      end
    end

    describe '#volume_title_number' do
      it 'is the number between a word and a " :"' do
        expect(helper).to receive(:params).at_least(:once).and_return({ f: { vol_title_ssi: ['Tome 21 : The Title'] } })
        expect(helper.volume_title_number).to eq '21'
      end

      it 'handles the lack of the volume title data proplery' do
        expect(helper).to receive(:params).at_least(:once).and_return({ f: { vol_title_ssi: [] } })
        expect(helper.volume_title_number).to be_nil
      end

      it 'handles malformed title data properly' do
        expect(helper).to receive(:params).at_least(:once).and_return({ f: { vol_title_ssi: ['ThingThatDoesNot : ConformToOurPattern'] } })
        expect(helper.volume_title_number).to be_nil
      end
    end
  end
end
