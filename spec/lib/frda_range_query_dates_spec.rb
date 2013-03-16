require "spec_helper"
require 'frda/range_query_dates'

describe Frda::RangeQueryDates do
  describe "searching by one date" do
    it "should search w/i a single date when only 1 full date is given" do
      range_query = Frda::RangeQueryDates.new("2013-03-21").range_query
      range_query.should match /\[2013-03-21.* TO 2013-03-21.*\]/
    end
    
    it "should search w/i a month when a single year and month is given" do
      range_query = Frda::RangeQueryDates.new("2013-03").range_query
      range_query.should match /\[2013-03-01.* TO 2013-03-31.*\]/
    end
    
    it "should add the appopriate ranges for a single year" do
      range_query = Frda::RangeQueryDates.new("2013").range_query
      range_query.should match /\[2013-01-01.* TO 2013-12-31.*\]/
    end
  end
  
  describe "searching a range of dates" do
    it "should search w/i the appropriate dates" do
      range_query = Frda::RangeQueryDates.new("2013-03-21", "2014-08-12").range_query
      range_query.should match /\[2013-03-21.* TO 2014-08-12.*\]/
    end
    
    it "should search from the beginning of the first given month to the end of the last given month" do
      range_query = Frda::RangeQueryDates.new("2013-03", "2014-08").range_query
      range_query.should match /\[2013-03-01.* TO 2014-08-31.*\]/
    end
    
    it "should search from the beginning of the first given year to the end of the last given year" do
      range_query = Frda::RangeQueryDates.new("2013", "2014").range_query
      range_query.should match /\[2013-01-01.* TO 2014-12-31.*\]/
    end
    
    describe "mixed formats" do
      it "should handle mixed month and year ranges" do
        range_query = Frda::RangeQueryDates.new("2013-02", "2014").range_query
        range_query.should match /\[2013-02-01.* TO 2014-12-31.*\]/
      end
      
      it "should handle mixed full and month ranges" do
        range_query = Frda::RangeQueryDates.new("2013-02", "2014-04-15").range_query
        range_query.should match /\[2013-02-01.* TO 2014-04-15.*\]/
      end
    end
  end
  
  describe "date oddities" do
    it "should handle the end of the month dates properly" do
      range_query = Frda::RangeQueryDates.new("2013-02", "2014-04").range_query
      range_query.should match /\[2013-02-01.* TO 2014-04-30.*\]/
    end
    it "should handle when the end date is nil" do
      range_query = Frda::RangeQueryDates.new("2013-03", nil).range_query
      range_query.should match /\[2013-03-01.* TO 2013-03-31.*\]/
    end
  end
  
end