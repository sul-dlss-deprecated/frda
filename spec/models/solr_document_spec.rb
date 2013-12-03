require "spec_helper"

describe SolrDocument do
  it "should behave like a SolrDocument" do
    doc = SolrDocument.new(:id => "12345")
    doc.should be_a SolrDocument
    doc[:id].should == "12345"
    doc.should respond_to :export_formats
  end
  
  describe "catalog_heading" do
    it "should get the correct field based on the locale passed in" do
      doc = SolrDocument.new(:id => "12345", :catalog_heading_etsimv => ["Something -- Something English"], :catalog_heading_ftsimv => ["Something -- Something French"])
      en_heading = doc.catalog_heading(:en)
      fr_heading = doc.catalog_heading(:fr)
      en_heading.length.should == 1 
      fr_heading.length.should == 1
      en_heading.first.should include "Something English" and en_heading.first.should_not include "Something French"
      fr_heading.first.should include "Something French" and fr_heading.first.should_not include "Something English"
    end
    it "should split the catalog heading field on double dashes" do
      doc = SolrDocument.new(:id => "12345", :catalog_heading_etsimv => ["Something -- Something Else -- Yet Another thing"])
      heading = doc.catalog_heading(:en)
      heading.length.should == 1
      heading.first.length.should == 3
      ["Something", "Something Else", "Yet Another thing"].each do |phrase|
        heading.first.should include phrase
      end
    end
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
    it "should return the requested dimension when one is specified" do
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
  
  describe "spoken_text" do
    before(:all) do
      @speech = "1234-|-M. Dorizy-|-This is a speech by a person."
      @unspoken = "1234-|-This is some unspoken text."
      @speech_bad = "M. Dorizy This is a speech by a person."
    end
    it "should parse the speech split on the appropriate delimiter" do
      speeches = SolrDocument.new({:spoken_text_ftsimv => [@speech]}, {}).spoken_text
      speeches.should be_a Array
      speeches.length.should == 1
      speeches.first.speaker.should == "M. Dorizy"
      speeches.first.text.should == "This is a speech by a person."
    end
    it "should be blank if the speech is unparsable" do
      speeches = SolrDocument.new({:spoken_text_ftsimv => [@speech_bad]}, {}).spoken_text
      speeches.should be_blank
    end
    it "should inform us if a speech has been highlighted" do
      hl_response = {'highlighting' => {'1234'=>{'spoken_text_ftsimv'=>["1234-|-M. Dorizy-|-This is a <em>speech</em> by a person."]}}}
      speeches = SolrDocument.new({:id => "1234", :spoken_text_ftsimv => [@speech]}, hl_response).spoken_text
      speeches.should be_a(Array)
      speeches.length.should == 1
      speeches.first.should be_highlighted
      speeches.first.text.should =~ /<em>/

      speeches = SolrDocument.new({:id => "1234", :spoken_text_ftsimv => [@speech]}, {}).spoken_text
      speeches.first.should_not be_highlighted
    end
    describe "highlighted_speeches" do
      it "should return only the highlighed speeches" do
        hl_response = {'highlighting' => {'1234'=>{'spoken_text_ftsimv'=>["1234-|-M. Dorizy-|-This is a <em>speech</em> by a person."]}}}
        speeches = SolrDocument.new({:id => "1234", :spoken_text_ftsimv => [@speech, @speech_bad]}, hl_response).highlighted_spoken_text
        speeches.should be_a Array
        speeches.length.should == 1
        speeches.first.should be_highlighted
        speeches.first.text.should =~ /<em>/
      end
      it "should return nil if no highlighting is available" do
        speeches = SolrDocument.new({:id => "1234", :spoken_text_ftsimv => [@speech, @speech_bad]}, {}).highlighted_spoken_text
        speeches.should be_nil
      end
      describe "highlighted_spoken_and_unspoken_text" do
        before(:all) do
          hl_response =  {  'highlighting' => {
                             '1234' => {
                               'spoken_text_ftsimv' => ["5555-|-M. Dorizy-|-This is a <em>speech</em> by a person."],
                               'unspoken_text_ftsimv' => ["4444-|-This is some <em>unspoken</em> text.",
                                                          "5555-|-This is <em>another</em> speech by a person."]
                             }
                           }
                         }
          @document = SolrDocument.new({:id => "1234", :spoken_text_ftsimv => ["5555-|-M. Dorizy-|-This is a speech by a person."], 
                                                   :unspoken_text_ftsimv => ["4444-|-This is some unspoken text.",
                                                                             "5555-|-This is another speech by a person."]}, hl_response)
        end
        it "should group speeches by page id" do
          @document.highlighted_spoken_and_unspoken_text.keys.should == ["4444", "5555"]
        end
        it "should sort speeches by page id" do
          @document.highlighted_spoken_and_unspoken_text.keys.should == ["5555", "4444"].sort
        end
        it "should aggregate both text flavors into highlighted_spoken_and_unspoken_text" do
          hl_response = {'highlighting' => {'1234'=>{'spoken_text_ftsimv'=>["1234-|-M. Dorizy-|-This is a <em>speech</em> by a person."], 'unspoken_text_ftsimv' => ["1234-|-This is some <em>unspoken</em> text."]}}}
          texts = SolrDocument.new({:id => "1234", :spoken_text_ftsimv => [@speech], :unspoken_text_ftsimv => [@unspoken]}, hl_response).highlighted_spoken_and_unspoken_text
          texts.should be_a Hash
          texts.keys.should == ["1234"]
          texts["1234"].should be_a Array
          texts["1234"].length.should == 2
          texts["1234"].all?{|t| t.is_a?(SpokenText) or t.is_a?(UnspokenText) }.should be_true
        end
      end
    end
  end
  
  describe "highlight glob fields" do
    describe "unspoken_text" do
      before(:all) do
        @hl_text1 = "dd123abc_00_0001-|-Some <em>text<em> on a page "
        @hl_text2 = "dd123abc_00_0002-|-Another piece of <em>text</em> on a page "
        @no_hl_text1 = "dd123abc_02_0002-|-Text that is not highlighted. "
        @no_hl_text2 = "dd123abc_02_0001-|-More text that is not highlighted. "
      end
      it "should reconstruct the highlighted fields array of fields from a giant glob" do
        fields = SolrDocument.new(:id => "123").send(:split_highlighted_unspoken_field_glob, ["#{@hl_text1} #{@hl_text2}"])
        fields.should be_a Array
        fields.length.should be 2
        fields.first.should match /^#{@hl_text1}/
        fields.last.should match /^#{@hl_text2}/
      end
      it "should not return any non-highlighted fields" do
        fields = SolrDocument.new(:id => "123").send(:split_highlighted_unspoken_field_glob, ["#{@no_hl_text1} #{@hl_text1} #{@hl_text2} #{@no_hl_text2}"])
        fields.should be_a Array
        fields.length.should be 2
        fields.first.should match /^#{@hl_text1}/
        fields.last.should match /^#{@hl_text2}/
      end
    end
    describe "spoken_text" do
      before(:all) do
        @hl_speech1 = "dd123abc_00_0001-|-Le President-|-A <em>speech<em> by the president "
        @hl_speech2 = "dd123abc_00_0002-|-Mr. Doe-|-Another <em>speech</em> with some text "
        @no_hl_speech1 = "dd123abc_02_0002-|-Mrs. Doe-|-A speech that is not highlighted. "
        @no_hl_speech2 = "dd123abc_02_0001-|-Mr. Dorzy-|-Another speech that is not highlighted. "
      end
      it "should reconstruct the highlighted fields array of fields from a giant glob" do
        fields = SolrDocument.new(:id => "123").send(:split_highlighted_spoken_field_glob, ["#{@hl_speech1} #{@hl_speech2}"])
        fields.should be_a Array
        fields.length.should be 2
        fields.first.should match /^#{@hl_speech1}/
        fields.last.should match /^#{@hl_speech2}/
      end
      it "should not return any non-highlighted fields" do
        fields = SolrDocument.new(:id => "123").send(:split_highlighted_spoken_field_glob, ["#{@no_hl_speech1} #{@hl_speech1} #{@hl_speech2} #{@no_hl_speech2}"])
        fields.should be_a Array
        fields.length.should be 2
        fields.first.should match /^#{@hl_speech1}/
        fields.last.should match /^#{@hl_speech2}/
      end
    end
  end
  
  describe "mods" do
    before(:all) do
      @mods_doc = SolrDocument.new({:id => "12345", :mods_xml => "<?xml version='1.0'?><mods><note>This is the first note.</note><note>This is the second note.</note></mods>"})
      @no_mods_doc = SolrDocument.new({:id => "54321"})
    end
    it "should return a Nokogiri::XML::Document when mods_xml is available" do
      @mods_doc.mods.should be_a Nokogiri::XML::Document
    end
    it "should provide an easy API to the elements in the XML" do
      @mods_doc.mods.note.length.should == 2
      @mods_doc.mods.note.first.text.should == "This is the first note."
      @mods_doc.mods.note.last.text.should == "This is the second note."
    end
    it "should return nil in the absence of mods_xml" do
      @no_mods_doc.mods.should be_nil
    end
  end
  describe "mods_xml_for_mods_display" do
    before(:all) do
      @xml = "<?xml version='1.0'?><mods><title>This is the first note.</title><subject displayLabel='Catalog heading'>This is a Catalog Heading</subject></mods>"
      @mods_doc = SolrDocument.new({:id => "12345", :mods_xml => @xml})
    end
    it "should remove catalog headings from MODS before sending to the ModsDisplay gem" do
      expect(@xml).to match(/This is a Catalog Heading/)
      expect(@mods_doc.mods_xml_for_mods_display).not_to match(/This is a Catalog Heading/)
    end
  end
end