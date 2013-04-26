require "spec_helper"

describe CatalogController do
  
  describe "solr_params_logic" do
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
  end
  
end