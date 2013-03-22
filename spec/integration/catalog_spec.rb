# encoding: UTF-8
require 'spec_helper'

describe("Search Pages",:type=>:request,:integration=>true) do
  
  before(:each) do

  end
    
  it "should show the collection highlights" do
    visit collection_highlights_path
    page.should have_content("Collection highlights")
    page.should have_content("Items from university correspondance.")
    page.should have_content("Items from official documents.")  
  end

  it "should show the AP home page" do
    visit ap_collection_path
    page.should have_content("The Archives parlementaires is a chronologically-ordered edited collection of sources on the French Revolution.")
    page.should have_content("1 - 5 of 5 volumes")
    page.should have_css('div.oneresult')
    page.should have_xpath("//img[contains(@src, \"APcoverimage.jpg\")]")
  end
  
  it "should show the Images home page" do
    visit images_collection_path    
    page.should have_content("The Images are composed of high-resolution digital images of approximately 12,000 individual visual items, primarily prints")
    page.should have_content("1 - 10 of 11 volumes")
    page.should have_css('div.oneresult')
    page.should have_xpath("//img[contains(@src, \"images_image_cropped.jpg\")]")
  end
  
  it "should show an AP detail page" do
    visit catalog_path(:id=>'wb029sv4796_00_0006')
    page.should have_content("M. le secrétaire, continuant la lecture des lettres, adresses et pétitions :")
    page.should have_xpath("//img[contains(@src, \"wb029sv4796/wb029sv4796_00_0006_medium.jpg\")]")
    page.should have_xpath("//a[contains(@href, \"/en/show_page?id=wb029sv4796&page_num=1\")]")
  end
  
  it "should show an Images detail page" do
    visit catalog_path(:id=>'bb018fc7286')
    page.should have_content("le 14.e juillet 1790 : [estampe]")
    page.should have_xpath("//img[contains(@src, \"bb018fc7286/T0000001_thumb.jpg\")]")    
    page.should have_xpath("//a[contains(@href, \"/en/catalog?f%5Bcollector_ssim%5D%5B%5D=Vinck%2C+Carl+de\")]")    
  end
  
  it "should search for an Images item" do
    pending
    # we aren't printing titles in the search results for the Image items at the moment.
    visit search_path(:q=>'bonaparte')
    page.should have_content("Bonaparte au Caire")
    page.should have_xpath("//img[contains(@src, \"zp695fd1911/T0000001_thumb\")]")
  end

  it "should search for an AP item" do
    visit search_path(:q=>'tome')
    page.should have_content("Tome 1 : 1789 – Introduction")
    page.should have_xpath("//img[contains(@src, \"jt959wc5586/jt959wc5586_00_0782_thumb\")]")  
  end
  
  describe "search options" do
    
    it "should return appropriate results for speaker autocomplete in json case insensitive, but only for AP data" do
      get speaker_suggest_path(:term=>'dor'),format: "json" # ap should have one result only
      response.status.should == 200
      response.body.should == '["Dorizy"]'  

      get speaker_suggest_path(:term=>'go'),format: "json" # ap should work lowercase letter first
      response.status.should == 200
      response.body.should == '["Gohier","Gossuin"]'          

      get speaker_suggest_path(:term=>'Go'),format: "json" # ap should work capital letter first
      response.status.should == 200
      response.body.should == '["Gohier","Gossuin"]'          

      get speaker_suggest_path(:term=>'rob'),format: "json" #image data should yield no results
      response.status.should == 200
      response.body.should == '[]'          

    end
    
    describe "in speeches by" do
      it "should return the correct number of results for a specific term and specific speaker" do
        visit root_path
        fill_in "q", :with => "verbal"
        check("speeches")
        fill_in "by-speaker", :with=> "Le Président" 
        find(:css, "[value='Search...']").click
        page.all(:css, ".oneresult").length.should == 1
        page.should have_content "1 to 1 of 1 volume"
        page.should have_content "Séance du jeudi 18 février 1790, au matin (1). "
      end
      it "should return more results when not restricted by speaker" do
        visit root_path
        fill_in "q", :with => "verbal"
        find(:css, "[value='Search...']").click
        page.all(:css, ".oneresult").length.should == 5
        page.should have_content "1 - 2 of 2 volumes "
      end      
    end
    
    describe "date range" do
       it "should limit the results by the dates specified" do
         visit root_path
         fill_in "q", :with => "*:*"
         check("dates")
         fill_in :"date-start", :with => "1780-05-19"
         fill_in :"date-end", :with => "1799-04-25"
         find(:css, "[value='Search...']").click
         
         page.all(:css, ".oneresult").length.should == 19
    
         fill_in :"date-start", :with => "1794-04-25"
         find(:css, "[value='Search...']").click
         
         page.all(:css, ".oneresult").length.should == 5
       end
     end
     
    describe "collection drop down" do
      it "should limit the search to the given collection" do
        visit root_path
        fill_in "q", :with => "*:*"
        select "Parliamentary archives", :from => "search_collection"
        find(:css, "[value='Search...']").click
        
        page.should have_content "1 - 5 of 5 volumes"
        
        select "Images of the French Revolution", :from => "search_collection"
        find(:css, "[value='Search...']").click
        
        page.should have_content "1 - 10 of 11 volume"
      end
    end
  end
  
  
  describe "grouped search results" do
    it "should group AP items together by tome/volume" do
      visit catalog_index_path(:q => "*:*")
      page.should have_xpath("//h2/a[text()='Tome 36 : Du 11 décembre 1791 au 1er janvier 1792']")
    end
    describe "facets" do
      it "should properly extend the facets module from Blacklight to return facets from the response correctly" do
        visit root_path
        click_link 'nonprojected graphic'
        page.should have_content("1 to 1 of 1 volume")
        page.should have_xpath("//img[contains(@src, \"image/bb018fc7286/T0000001_thumb.jpg\")]")        
      end
    end
    describe "pagination" do
      pending
    end
  end
  
  describe "non grouped results" do
    it "should be returned when we're on a faceted search for vol_title_ssi" do
      visit catalog_index_path(:f => {:vol_title_ssi => ["Tome 36 : Du 11 décembre 1791 au 1er janvier 1792"]})
      page.should_not have_xpath("//h2/a[text()='Tome 36 : Du 11 décembre 1791 au 1er janvier 1792']")
      # make sure we're also getting results
      page.all(:css, ".oneresult").length.should == 4
    end
  end
  
end