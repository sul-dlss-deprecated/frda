class CollectionHighlight < ActiveRecord::Base
  attr_accessible :name_en,:name_fr,:description_fr,:description_en,:image_url,:sort_order
  has_many :collection_highlight_items
  
  def query
    collection_highlight_items.map{|item| item.item_id}.join(" or ")
  end
  
end
