require "spec_helper"

describe SpokenText do
  
  before :all do
    @spoken_text = "1234-|-John Doe-|-This is a speech."
    @highlighted_text = "1234-|-John Doe-|-This is a <em>highlighted</em> speech."
    @highlighted_speaker = "1234-|-<em>John</em> Doe-|-This is a <em>highlighted</em> speech."
  end
  
  describe "page_id" do
    it "should return the first element in the spoken_text delimited field" do
      SpokenText.new(@spoken_text).page_id.should == "1234"
    end
  end
  
  describe "speaker" do
    it "should return the second element in the spoken_text delimited field" do
      SpokenText.new(@spoken_text).speaker.should == "John Doe"
    end
    it "should strip any highlighting if present" do
      SpokenText.new(@highlighted_speaker).speaker.should_not include "<em>"
    end
  end
  
  describe "text" do
    it "should return the third element in the spoken_text delmited field" do
      SpokenText.new(@spoken_text).text.should == "This is a speech."
    end
    describe "highlighted?" do
      it "should return true if highlighting is present in the text" do
        SpokenText.new(@highlighted_text).should be_highlighted
      end
      it "should return false if highlighting is not present in the text" do
        SpokenText.new(@spoken_text).should_not be_highlighted
      end
    end
  end
end