# encoding: utf-8
require "spec_helper"

describe SolrDocument do
  it "should behave like a SolrDocument" do
    doc = SolrDocument.new(:id => "12345")
    expect(doc).to be_a SolrDocument
    expect(doc[:id]).to eq("12345")
    expect(doc).to respond_to :export_formats
  end

  describe "catalog_heading" do
    it "should get the correct field based on the locale passed in" do
      doc = SolrDocument.new(:id => "12345", :catalog_heading_etsimv => ["Something -- Something English"], :catalog_heading_ftsimv => ["Something -- Something French"])
      en_heading = doc.catalog_heading(:en)
      fr_heading = doc.catalog_heading(:fr)
      expect(en_heading.length).to eq(1)
      expect(fr_heading.length).to eq(1)
      expect(en_heading.first).to include "Something English" and expect(en_heading.first).not_to include "Something French"
      expect(fr_heading.first).to include "Something French" and expect(fr_heading.first).not_to include "Something English"
    end
    it "should split the catalog heading field on double dashes" do
      doc = SolrDocument.new(:id => "12345", :catalog_heading_etsimv => ["Something -- Something Else -- Yet Another thing"])
      heading = doc.catalog_heading(:en)
      expect(heading.length).to eq(1)
      expect(heading.first.length).to eq(3)
      ["Something", "Something Else", "Yet Another thing"].each do |phrase|
        expect(heading.first).to include phrase
      end
    end
  end

  describe "images" do
    before(:all) do
      @images = SolrDocument.new({:image_id_ssm => ["abc123", "cba321"]}).images
    end
    it "should point to the test URL" do
      @images.each do |image|
        expect(image).to include Frda::Application.config.stacks_url
      end
    end
    it "should link to the image identifier field " do
      @images.each do |image|
        expect(image).to match(/abc123|cba321/)
      end
    end
    it "should have the proper default image dimension when no size is specified" do
      @images.each do |image|
        expect(image).to match(/#{SolrDocument.image_dimensions[:default]}/)
      end
    end
    it "should return the requested dimension when one is specified" do
      SolrDocument.new({:image_id_ssm => ["abc123", "cba321"]}).images(:size=>:large).each do |image|
        expect(image).to match(/#{SolrDocument.image_dimensions[:large]}/)
      end
    end
    it "should return [] when the document does not have an image identifier field" do
      expect(SolrDocument.new(:id => "12345").images).to eq([])
    end
    describe "image dimensions" do
      it "should be a hash of configurations" do
        expect(SolrDocument.image_dimensions).to be_a Hash
        expect(SolrDocument.image_dimensions).to have_key :default
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
      expect(speeches).to be_a Array
      expect(speeches.length).to eq(1)
      expect(speeches.first.speaker).to eq("M. Dorizy")
      expect(speeches.first.text).to eq("This is a speech by a person.")
    end
    it "should be blank if the speech is unparsable" do
      speeches = SolrDocument.new({:spoken_text_ftsimv => [@speech_bad]}, {}).spoken_text
      expect(speeches).to be_blank
    end
    it "should inform us if a speech has been highlighted" do
      hl_response = {'highlighting' => {'1234'=>{'spoken_text_ftsimv'=>["1234-|-M. Dorizy-|-This is a <em>speech</em> by a person."]}}}
      speeches = SolrDocument.new({:id => "1234", :spoken_text_ftsimv => [@speech]}, hl_response).spoken_text
      expect(speeches).to be_a(Array)
      expect(speeches.length).to eq(1)
      expect(speeches.first).to be_highlighted
      expect(speeches.first.text).to match(/<em>/)

      speeches = SolrDocument.new({:id => "1234", :spoken_text_ftsimv => [@speech]}, {}).spoken_text
      expect(speeches.first).not_to be_highlighted
    end
    describe "highlighted_speeches" do
      it "should return only the highlighed speeches" do
        hl_response = {'highlighting' => {'1234'=>{'spoken_text_ftsimv'=>["1234-|-M. Dorizy-|-This is a <em>speech</em> by a person."]}}}
        speeches = SolrDocument.new({:id => "1234", :spoken_text_ftsimv => [@speech, @speech_bad]}, hl_response).highlighted_spoken_text
        expect(speeches).to be_a Array
        expect(speeches.length).to eq(1)
        expect(speeches.first).to be_highlighted
        expect(speeches.first.text).to match(/<em>/)
      end
      it "should return nil if no highlighting is available" do
        speeches = SolrDocument.new({:id => "1234", :spoken_text_ftsimv => [@speech, @speech_bad]}, {}).highlighted_spoken_text
        expect(speeches).to be_nil
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
          expect(@document.highlighted_spoken_and_unspoken_text.keys).to eq(["4444", "5555"])
        end
        it "should sort speeches by page id" do
          expect(@document.highlighted_spoken_and_unspoken_text.keys).to eq(["5555", "4444"].sort)
        end
        it "should aggregate both text flavors into highlighted_spoken_and_unspoken_text" do
          hl_response = {'highlighting' => {'1234'=>{'spoken_text_ftsimv'=>["1234-|-M. Dorizy-|-This is a <em>speech</em> by a person."], 'unspoken_text_ftsimv' => ["1234-|-This is some <em>unspoken</em> text."]}}}
          texts = SolrDocument.new({:id => "1234", :spoken_text_ftsimv => [@speech], :unspoken_text_ftsimv => [@unspoken]}, hl_response).highlighted_spoken_and_unspoken_text
          expect(texts).to be_a Hash
          expect(texts.keys).to eq(["1234"])
          expect(texts["1234"]).to be_a Array
          expect(texts["1234"].length).to eq(2)
          expect(texts["1234"].all?{|t| t.is_a?(SpokenText) or t.is_a?(UnspokenText) }).to be_truthy
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
        expect(fields).to be_a Array
        expect(fields.length).to be 2
        expect(fields.first).to match /^#{@hl_text1}/
        expect(fields.last).to match /^#{@hl_text2}/
      end
      it "should not return any non-highlighted fields" do
        fields = SolrDocument.new(:id => "123").send(:split_highlighted_unspoken_field_glob, ["#{@no_hl_text1} #{@hl_text1} #{@hl_text2} #{@no_hl_text2}"])
        expect(fields).to be_a Array
        expect(fields.length).to be 2
        expect(fields.first).to match /^#{@hl_text1}/
        expect(fields.last).to match /^#{@hl_text2}/
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
        expect(fields).to be_a Array
        expect(fields.length).to be 2
        expect(fields.first).to match /^#{@hl_speech1}/
        expect(fields.last).to match /^#{@hl_speech2}/
      end
      it "should not return any non-highlighted fields" do
        fields = SolrDocument.new(:id => "123").send(:split_highlighted_spoken_field_glob, ["#{@no_hl_speech1} #{@hl_speech1} #{@hl_speech2} #{@no_hl_speech2}"])
        expect(fields).to be_a Array
        expect(fields.length).to be 2
        expect(fields.first).to match /^#{@hl_speech1}/
        expect(fields.last).to match /^#{@hl_speech2}/
      end
    end
  end

  describe "mods" do
    before(:all) do
      @mods_doc = SolrDocument.new({:id => "12345", :mods_xml => "<?xml version='1.0'?><mods><note>This is the first note.</note><note>This is the second note.</note></mods>"})
      @no_mods_doc = SolrDocument.new({:id => "54321"})
    end
    it "should return a Nokogiri::XML::Document when mods_xml is available" do
      expect(@mods_doc.mods).to be_a Stanford::Mods::Record
    end
    it "should provide an easy API to the elements in the XML" do
      expect(@mods_doc.mods.note.length).to eq(2)
      expect(@mods_doc.mods.note.first.text).to eq("This is the first note.")
      expect(@mods_doc.mods.note.last.text).to eq("This is the second note.")
    end
    it "should return nil in the absence of mods_xml" do
      expect(@no_mods_doc.mods).to be_nil
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

  describe "get ocr text" do
    it "should look for multiple OCR file locations" do
      doc = SolrDocument.new(:id => "12345",:ocr_id_ss=>'somefilename_99_test.txt')
      expect(doc.possible_ocr_filenames).to eq ['somefilename_99_test.txt','somefilename_test.txt','somefilename_00_test.txt']
    end
    it "should return no text if the file cannot be found" do
      doc = SolrDocument.new(:id => "12345",:ocr_id_ss=>'somefilename_99_test.txt')
      expect(doc.formatted_page_text).to eq ''
      expect(doc.txt_file).to eq ''
    end
    it "should return text if a file was found" do
      doc = SolrDocument.new(:id => "wb029sv4796_00_0111",:druid_ssi=>"wb029sv4796", :ocr_id_ss=>"wb029sv4796_99_0111.txt")
      expect(doc.formatted_page_text).to include '118 [Assemblée nationale législative.] ARCHIVES PA1'
      expect(doc.txt_file).to eq 'https://stacks.stanford.edu/file/druid:wb029sv4796/wb029sv4796_99_0111.txt'
    end
  end

  describe 'get_actual_txt_file' do
    it 'should convert non-UTF-8 encoding to UTF-8' do
      doc = SolrDocument.new(:id => "fz023dp4399_00_0030",:druid_ssi=>"fz023dp4399", :ocr_id_ss=>"fz023dp4399_00_0030.txt")
      expect(doc.formatted_page_text).not_to include "g\xE9n. 1789. Cahiere.] ARCHIVES PARLEMENTAIRES. [S\xE9n\xE9chauss\xE9e d'Angoonois.]" # Badly encoded string
      expect(doc.formatted_page_text).to include "gén. 1789. Cahiere.] ARCHIVES PARLEMENTAIRES. [Sénéchaussée d'Angoonois.]" # Correctly encoded string
    end
    it 'should not change text that is already UTF-8' do
      doc = SolrDocument.new(:id => "mc666yy3026_99_0014",:druid_ssi=>"mc666yy3026", :ocr_id_ss=>"mc666yy3026_99_0014.txt")
      expect(doc.formatted_page_text).to include "Art. 14. Qu'il ne serà fait aucun emprunt que de l'agrément dès Etats généraux; que"
    end
  end
end
