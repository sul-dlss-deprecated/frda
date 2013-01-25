# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

def add_items(items,coll)
  items.each {|item| coll.collection_highlight_items << CollectionHighlightItem.create(item_id:"#{item}")}
end

CollectionHighlight.find(:all).each {|h| h.destroy}
CollectionHighlightItem.find(:all).each {|hi| hi.destroy}

c1=CollectionHighlight.create(sort_order:1,name_en:'University Correspondence',name_fr:'University Correspondance',description_en:'Items from university correspondance.',description_fr:'Items from university correspondance.',image_url:'bv-sample.png')
c2=CollectionHighlight.create(sort_order:2,name_en:'Official Documents',name_fr:'Official Documents',description_en:'Items from official documents.',description_fr:'Items from official documents.',image_url:'bv-sample-2.png')
c3=CollectionHighlight.create(sort_order:3,name_en:'Personal Letters',name_fr:'Personal Letters',description_en:'Items from personal letters.',description_fr:'Items from personal letters.',image_url:'bv-sample-3.png')

c1_items=%w{ref18 ref22 ref25 ref46}
c2_items=%w{ref100 ref106 ref114}
c3_items=%w{ref333 ref331 ref329 ref327}

add_items(c1_items,c1)
add_items(c2_items,c2)
add_items(c3_items,c3)

