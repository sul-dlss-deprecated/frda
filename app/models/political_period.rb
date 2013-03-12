class PoliticalPeriod < ActiveRecord::Base
  attr_accessible :name_en,:name_fr,:start_date,:end_date,:sort_order
end
