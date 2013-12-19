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
        controller.stub(:on_home_page).and_return(true)
        controller.send(:exclude_highlighting, solr_params, user_params)
        solr_params.should have_key :hl
        solr_params[:hl].should == "false"
        solr_params.should have_key :rows
        solr_params[:rows].should == 0
      end
      it "should turn highlighting off and not return any rows for the AP landing page" do
        solr_params = {}
        user_params = {}
        controller.stub(:on_ap_landing_page).and_return(true)
        controller.send(:exclude_highlighting, solr_params, user_params)
        solr_params.should have_key :hl
        solr_params[:hl].should == "false"
        solr_params.should have_key :rows
        solr_params[:rows].should == 0
      end
      it "should not not turn highlighting off or restrict rows is we are not on the home page" do
        solr_params = {}
        user_params = {}
        controller.stub(:on_home_page).and_return(false)
        controller.send(:exclude_highlighting, solr_params, user_params)
        solr_params.should_not have_key :hl
        solr_params.should_not have_key :rows
      end
      it "should not not turn highlighting off or restrict rows is we are on the AP landing page" do
        solr_params = {}
        user_params = {}
        controller.stub(:on_home_page).and_return(false)
        controller.stub(:on_ap_landing_page).and_return(false)
        controller.send(:exclude_highlighting, solr_params, user_params)
        solr_params.should_not have_key :hl
        solr_params.should_not have_key :rows
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
        controller.stub(:on_ap_landing_page).and_return(true)
        controller.send(:pivot_facet_on_ap_landing_page, solr_params, user_params)
        solr_params.should have_key :"facet.pivot"
        solr_params[:"facet.pivot"].should == @pivot
      end
      it "should set the limit (index) and sort (-1) on the facet fields in the pivot" do
        solr_params = {}
        user_params = {}
        controller.stub(:on_ap_landing_page).and_return(true)
        controller.send(:pivot_facet_on_ap_landing_page, solr_params, user_params)
        [@fist_facet, @second_facet].each do |facet|
          solr_params[:"f.#{facet}.facet.limit"].should == "-1"
          solr_params[:"f.#{facet}.facet.sort"].should == "index"
        end
      end
      it "should not set any solr params on pages that are not the ap landing page" do
        solr_params = {}
        user_params = {}
        controller.stub(:on_ap_landing_page).and_return(false)
        controller.send(:pivot_facet_on_ap_landing_page, solr_params, user_params)
        solr_params.should == {}
      end

    end
  end
  
end