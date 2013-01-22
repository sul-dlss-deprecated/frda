class CollectionHighlightItem < ActiveRecord::Base
  attr_accessible :collection_highlight_id,:item_id
  belongs_to :collection_highlight
end
