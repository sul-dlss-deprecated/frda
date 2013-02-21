require "spec_helper"

describe SolrDocument do
  it "should behave like a SolrDocument" do
    doc = SolrDocument.new(:id => "12345")
    doc.should be_a SolrDocument
    doc[:id].should == "12345"
    doc.should respond_to :export_formats
  end
  
  describe "images" do
    before(:all) do
      @images = SolrDocument.new({:image_id_ssm => ["abc123", "cba321"]}).images
    end
    it "should point to the test URL" do
      @images.each do |image|
        image.should include Frda::Application.config.stacks_url
      end
    end
    it "should link to the image identifier field " do
      @images.each do |image|
        image.should =~ /abc123|cba321/
      end
    end
    it "should have the proper default image dimension when no size is specified" do
      @images.each do |image|
        image.should =~ /#{SolrDocument.image_dimensions[:default]}/
      end
    end
    it "should return the requested dimentsion when one is specified" do
      SolrDocument.new({:image_id_ssm => ["abc123", "cba321"]}).images(:size=>:large).each do |image|
        image.should =~ /#{SolrDocument.image_dimensions[:large]}/
      end
    end
    it "should return [] when the document does not have an image identifier field" do
      SolrDocument.new(:id => "12345").images.should eq([])
    end
    describe "image dimensions" do
      it "should be a hash of configurations" do
        SolrDocument.image_dimensions.should be_a Hash
        SolrDocument.image_dimensions.should have_key :default
      end
    end
  end
  
end