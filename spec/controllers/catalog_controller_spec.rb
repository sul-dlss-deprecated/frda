require "spec_helper"

describe CatalogController do
  
  describe "solr_params_logic" do
    describe "search within speeches" do
      before :each do
        @speaker = "President"
        @text = "I am the person in charge!"
        @solr_params = {}
        @user_params = {"speeches" => "1", "by-speaker" => @speaker, "q" => @text}
      end
      it "should prepend the query with the appropriate solr field" do
        controller.send(:search_within_speeches, @solr_params, @user_params)
        expect(@solr_params[:q]).to match /^(\w+):\"/
      end
      it "should surround the speaker with 'aaa' and 'zzz'" do
        controller.send(:search_within_speeches, @solr_params, @user_params)
        expect(@solr_params[:q]).to match /:\"aaa#{@speaker}zzz #{@text}\"/
      end
      it "should append the query with an boost value" do
        controller.send(:search_within_speeches, @solr_params, @user_params)
        expect(@solr_params[:q]).to match /\"~(\d+)$/
      end
      it "should remove quotes in the user query param" do
        user_params = {"q" => '"HEY, this is a phrase"', "speeches" => "1", "by-speaker" => @speaker}
        controller.send(:search_within_speeches, @solr_params, user_params)
        expect(user_params["q"]).to eq '"HEY, this is a phrase"'
        expect(@solr_params[:q]).not_to match user_params["q"]
      end
    end
    describe "exclude_highlighting" do
      it "should turn highlighting off and not return any rows for the home page" do
        solr_params = {}
        user_params = {}
        allow(controller).to receive(:on_home_page).and_return(true)
        controller.send(:exclude_highlighting, solr_params, user_params)
        expect(solr_params).to have_key :hl
        expect(solr_params[:hl]).to eq("false")
        expect(solr_params).to have_key :rows
        expect(solr_params[:rows]).to eq(0)
      end
      it "should turn highlighting off and not return any rows for the AP landing page" do
        solr_params = {}
        user_params = {}
        allow(controller).to receive(:on_ap_landing_page).and_return(true)
        controller.send(:exclude_highlighting, solr_params, user_params)
        expect(solr_params).to have_key :hl
        expect(solr_params[:hl]).to eq("false")
        expect(solr_params).to have_key :rows
        expect(solr_params[:rows]).to eq(0)
      end
      it "should not not turn highlighting off or restrict rows is we are not on the home page" do
        solr_params = {}
        user_params = {}
        allow(controller).to receive(:on_home_page).and_return(false)
        controller.send(:exclude_highlighting, solr_params, user_params)
        expect(solr_params).not_to have_key :hl
        expect(solr_params).not_to have_key :rows
      end
      it "should not not turn highlighting off or restrict rows is we are on the AP landing page" do
        solr_params = {}
        user_params = {}
        allow(controller).to receive(:on_home_page).and_return(false)
        allow(controller).to receive(:on_ap_landing_page).and_return(false)
        controller.send(:exclude_highlighting, solr_params, user_params)
        expect(solr_params).not_to have_key :hl
        expect(solr_params).not_to have_key :rows
      end
    end

    describe "pivot_facet_on_ap_landing_page" do
      before(:all) do
        @fist_facet = "result_group_ssort"
        @second_facet = "div2_ssort"
        @pivot = [@fist_facet, @second_facet].join(",")
      end

      it "should set the facet pivot on the ap landing page" do
        solr_params = {}
        user_params = {}
        allow(controller).to receive(:on_ap_landing_page).and_return(true)
        controller.send(:pivot_facet_on_ap_landing_page, solr_params, user_params)
        expect(solr_params).to have_key :"facet.pivot"
        expect(solr_params[:"facet.pivot"]).to eq(@pivot)
      end
      it "should set the limit (index) and sort (-1) on the facet fields in the pivot" do
        solr_params = {}
        user_params = {}
        allow(controller).to receive(:on_ap_landing_page).and_return(true)
        controller.send(:pivot_facet_on_ap_landing_page, solr_params, user_params)
        [@fist_facet, @second_facet].each do |facet|
          expect(solr_params[:"f.#{facet}.facet.limit"]).to eq("-1")
          expect(solr_params[:"f.#{facet}.facet.sort"]).to eq("index")
        end
      end
      it "should not set any solr params on pages that are not the ap landing page" do
        solr_params = {}
        user_params = {}
        allow(controller).to receive(:on_ap_landing_page).and_return(false)
        controller.send(:pivot_facet_on_ap_landing_page, solr_params, user_params)
        expect(solr_params).to eq({})
      end

    end
  end
  describe "subject search linking" do
    before :each do
      @link = controller.send(:subject_search_link, {:value => 'This is the value'})
    end
    it "should pass the original value as the q parameter" do
      expect(@link).to match /\?|&q=This\+is\+the\+value&|^/
    end
    it "should limit to the Images collection" do
      expect(@link).to match /\?|&f%5Bcollection_ssi.*=#{Frda::Application.config.images_id}&|^/
    end
    it "should force an exact match" do
      expect(@link).to match /\?|&exact=1&|^/
    end
  end
end