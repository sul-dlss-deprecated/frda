require "spec_helper"

describe SpokenText do
  
  before :all do
    @spoken_text = "1234-|-John Doe-|-This is a speech."
    @anchored_speaker = "1234-|-aaaJohn Doezzz-|-This is a speech."
    @highlighted_text = "1234-|-John Doe-|-This is a <em>highlighted</em> speech."
    @highlighted_speaker = "1234-|-<em>John</em> Doe-|-This is a <em>highlighted</em> speech."
  end
  
  describe "page_id" do
    it "should return the first element in the spoken_text delimited field" do
      expect(SpokenText.new(@spoken_text).page_id).to eq("1234")
    end
  end
  
  describe "speaker" do
    it "should return the second element in the spoken_text delimited field" do
      expect(SpokenText.new(@spoken_text).speaker).to eq("John Doe")
    end
    it "should strip the anchor strings from the speaker" do
      expect(SpokenText.new(@anchored_speaker).speaker).to eq("John Doe")
    end
    it "should strip any highlighting if present" do
      expect(SpokenText.new(@highlighted_speaker).speaker).not_to include "<em>"
    end
  end
  
  describe "text" do
    it "should return the third element in the spoken_text delmited field" do
      expect(SpokenText.new(@spoken_text).text).to eq("This is a speech.")
    end
    describe "highlighted?" do
      it "should return true if highlighting is present in the text" do
        expect(SpokenText.new(@highlighted_text)).to be_highlighted
      end
      it "should return false if highlighting is not present in the text" do
        expect(SpokenText.new(@spoken_text)).not_to be_highlighted
      end
    end
  end
end