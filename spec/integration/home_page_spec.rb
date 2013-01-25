require 'spec_helper'

describe("Home Page",:type=>:request,:integration=>true) do
  
    it "should render the home page with some text" do
        visit root_path
        page.should have_content("The French Revolution Digital Archive (FRDA) is a multi-year collaboration of the Stanford University Libraries and the")
    end
  
end