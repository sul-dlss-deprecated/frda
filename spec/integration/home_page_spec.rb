require 'spec_helper'

describe("Home Page",:type=>:request,:integration=>true) do
  
    it "should render the home page with some text and without collection facet" do
        visit root_path
        page.should have_content("The French Revolution Digital Archive (FRDA) is a multi-year collaboration of the Stanford University Libraries and the")
        page.should_not have_css("div.blacklight-collection_ssi") # should not have collection facet
    end
  
end