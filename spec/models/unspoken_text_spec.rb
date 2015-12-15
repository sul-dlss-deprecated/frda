require "spec_helper"

describe UnspokenText do

  before :all do
    @unspoken_text = "1234-|-This is unspoken text."
    @highlighted_text = "1234-|-This is <em>highlighted</em> unspoken text."
  end
  
  describe "page_id" do
    it "should return the first element in the spoken_text delimited field" do
      expect(UnspokenText.new(@unspoken_text).page_id).to eq("1234")
    end
  end
  
  describe "text" do
    it "should return the third element in the spoken_text delmited field" do
      expect(UnspokenText.new(@unspoken_text).text).to eq("This is unspoken text.")
    end
    describe "highlighted?" do
      it "should return true if highlighting is present in the text" do
        expect(UnspokenText.new(@highlighted_text)).to be_highlighted
      end
      it "should return false if highlighting is not present in the text" do
        expect(UnspokenText.new(@unspoken_text)).not_to be_highlighted
      end
    end
  end
  
end