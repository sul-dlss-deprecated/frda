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
    page.should have_css('ul.image-grid')
    page.should have_xpath("//img/@src['https://stacks.stanford.edu/image/wb029sv4796/wb029sv4796_00_0005_thumb.jpg']")
  end
  
  it "should show the Images home page" do
    visit images_collection_path    
    page.should have_content("The Images are composed of high-resolution digital images of approximately 12,000 individual visual items, primarily prints")
    page.should have_content("1 to 1 of 1 volume")
    page.should have_css('ul.image-grid')
    page.should have_xpath("//img/@src['https://stacks.stanford.edu/image/bb018fc7286/T0000001_thumb.jpg']")    
  end
  
  it "should show an AP detail page" do
    visit catalog_path(:id=>'wb029sv4796_00_0006')
    page.should have_content("Pour concilier tous les esprits, on peut, en")
    page.should have_xpath("//img/@src['https://stacks.stanford.edu/image/wb029sv4796/wb029sv4796_00_0006_medium.jpg']")
    page.should have_xpath("//a/@href['/en/catalog?f%5Bvol_title_ssi%5D%5B%5D=Tome+36+%3A+Du+11+d%C3%A9cembre+1791+au+1er+janvier+1792']")    
  end
  
  it "should show an Images detail page" do
    visit catalog_path(:id=>'bb018fc7286')
    page.should have_content("le 14.e juillet 1790 : [estampe]")
    page.should have_xpath("//img/@src['https://stacks.stanford.edu/image/bb018fc7286/T0000001_thumb.jpg']")
    page.should have_xpath("//a/@href['/en/catalog?f%5Bdate_issued_ssim%5D%5B%5D=1790']")
    
  end
  
  describe "grouped search results" do
    it "should group AP items together by tome/volume" do
      visit catalog_index_path(:q => "*:*", :view => "default")
      page.should have_xpath("//h4[text()='Tome 36 : Du 11 décembre 1791 au 1er janvier 1792 (4 occurrences)']")
    end
    describe "facets" do
      pending
    end
    describe "pagination" do
      pending
    end
  end
  
end