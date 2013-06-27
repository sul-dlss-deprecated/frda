class CategoryFr < ActiveRecord::Base
  attr_accessible :name, :parent_id, :position
  acts_as_nested_set
end
