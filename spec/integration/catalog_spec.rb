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
    #page.should have_content("The Archives parlementaires is a chronologically-ordered edited collection of sources on the French Revolution.")
    page.should have_content("1 volume found")
    page.should have_css('div.oneresult')
    page.should have_xpath("//img[contains(@src, \"APcoverimage.jpg\")]")
  end
  
  it "should show the Images home page" do
    visit images_collection_path
    #page.should have_content("The Images are composed of high-resolution digital images of approximately 12,000 individual visual items, primarily prints")
    page.should have_content("1 - 10 of 11 images")
    page.should have_css('div.oneresult')
    page.should have_xpath("//img[contains(@src, \"images_image_cropped.jpg\")]")
  end
  
  it "should show an AP detail page" do
    visit catalog_path(:id=>'wb029sv4796_00_0006')
    page.should have_content("M. le secrétaire, continuant la lecture des lettres, adresses et pétitions :")
    page.should have_xpath("//img[contains(@src, \"wb029sv4796/wb029sv4796_00_0006_medium.jpg\")]")
    page.should have_xpath("//a[contains(@href, \"/en/show_page?from_id=wb029sv4796_00_0006&id=wb029sv4796&page_seq=1\")]")
  end

  it "should go to a specific AP detail page by page sequence (like in paging controls)" do
    visit show_page_path(:from_id=>'wb029sv4796_00_0006',:id=>'wb029sv4796',:page_seq=>'3')
    current_path.should == catalog_path('en',:id=>'wb029sv4796_00_0007')
  end

  it "should return to the starting page if the specified page is not found" do
    visit show_page_path(:from_id=>'wb029sv4796_00_0006',:id=>'wb029sv4796',:page_seq=>'5555')
    current_path.should == catalog_path('en',:id=>'wb029sv4796_00_0006')
    page.should have_content('The selected page was not found.')
  end

  it "should go to a specific AP detail page by specifing a specific page number" do
    visit catalog_path(:id=>'wb029sv4796_00_0005')
    fill_in "page_num", :with => "2"
    click_button "Go"
    current_path.should == catalog_path('en',:id=>'wb029sv4796_00_0006')
  end

  it "should return to the starting page if an invalid page number is entered" do
    visit catalog_path(:id=>'wb029sv4796_00_0005')
    fill_in "page_num", :with => "5555"
    click_button "Go"
    current_path.should == catalog_path('en',:id=>'wb029sv4796_00_0005')
    page.should have_content('The selected page was not found.')
  end

  it "should go to the first page of a new session when selected in the drop down" do
    visit catalog_path(:id=>'wb029sv4796_00_0005')
    select "Séance du dimanche 11 décembre 1792", :from => "session_title"
    click_button "Go"
    current_path.should == catalog_path('en',:id=>'wb029sv4796_00_0006')
  end
  
  it "should show an Images detail page" do
    visit catalog_path(:id=>'bb018fc7286')
    page.should have_content("le 14.e juillet 1790 : [estampe]")
    page.should have_xpath("//img[contains(@src, \"bb018fc7286/T0000001_thumb.jpg\")]")
    page.should have_xpath("//dt", :text => "Genre")
    page.should have_xpath("//dd", :text => "Picture")
  end

  it "should include a colon in an Images detail page title when there is a Mods subTitle" do
    visit catalog_path(:id=>'bb018fc7286') # item has both Mods title and subTitle fields
    page.first('h3').text.should == 'Pacte fédératif des Français le 14.e juillet 1790 : [estampe]'
  end

  it "should not include a colon in an Images detail page title when there is not a Mods subTitle" do
    visit catalog_path(:id=>'bg698df3242') # item does not have a Mods subTitle field
    page.should_not have_xpath("//h3[contains(., '[:]')]")
  end
  
  it "should search for an Images item" do
    visit search_path(:q=>'bonaparte')
    page.should have_content("Bonaparte au Caire")
    page.should have_xpath("//img[contains(@src, \"zp695fd1911/T0000001_thumb\")]")
  end

  it "should search for an AP item" do
    visit search_path(:q=>'Lafayette')
    page.should have_content("Tome 8 : Du 5 mai 1789 au 15 septembre 1789")
    page.should have_xpath("//img[contains(@src, \"bm916nx5550/bm916nx5550_00_0301_thumb\")]")  
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
        fill_in "q", :with => "Lafayette"
        check("speeches")
        fill_in "by-speaker", :with=> "Le comte de Mirabeau" 
        find(:css, "[value='Search...']").click
        page.all(:css, ".oneresult").length.should == 1
        page.should have_content "Séance du 15 juillet 1789"
      end
      it "should return more results when not restricted by speaker" do
        visit root_path
        fill_in "q", :with => "Lafayette"
        find(:css, "[value='Search...']").click
        page.all(:css, ".oneresult").length.should == 2
        page.should have_content "Séance du 15 juillet 1789"
        page.should have_content "Séance du 16 juillet 1789"
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
         
         page.all(:css, ".oneresult").length.should == 12
    
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
        
        page.should have_content "1 volume found"
        
        select "Images of the French Revolution", :from => "search_collection"
        find(:css, "[value='Search...']").click
        
        page.should have_content "1 - 10 of 11 images"
      end
    end
  end
  
  
  describe "grouped search results" do
    it "should group AP items together by tome/volume" do
      visit catalog_index_path(:q => "*:*")
      page.should have_xpath("//li/a[text()='Tome 8 : Du 5 mai 1789 au 15 septembre 1789']")
    end
    describe "facets" do
      it "should properly extend the facets module from Blacklight to return facets from the response correctly" do
        visit root_path
        click_link 'nonprojected graphic'
        page.should have_content("1 volume found")
        page.should have_xpath("//img[contains(@src, \"image/bb018fc7286/T0000001_thumb.jpg\")]")        
      end
    end
    describe "pagination" do
      pending
    end
  end
  
  describe "non grouped results" do
    it "should be returned when we're on a faceted search for vol_title_ssi" do
      visit catalog_index_path(:f => {:vol_title_ssi => ["Tome 8 : Du 5 mai 1789 au 15 septembre 1789"]})
      page.should_not have_xpath("//h2/a[text()='Tome 8 : Du 5 mai 1789 au 15 septembre 1789']")
      # make sure we're also getting results
      page.all(:css, ".oneresult").length.should == 2
    end
  end
  
end