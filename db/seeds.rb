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

c1=CollectionHighlight.create(
  sort_order:1,
  name_en:'University Correspondence',
  name_fr:'University Correspondance',
  description_en:'Items from university correspondance. Pellentesque habitant morbi tristique senectus et
  netus et malesuada fames ac turpis egestas. Vestibulum tortor quam, feugiat vitae, ultricies eget, tempor
  sit amet, ante. Donec eu libero sit amet quam egestas semper. Aenean ultricies mi vitae est. Mauris
  placerat eleifend leo.',
  description_fr:'Items from university correspondance. In French',
  image_url:'https://stacks.stanford.edu/image/bb101kw2226/T0000001_thumb.jpg'
)
c2=CollectionHighlight.create(
  sort_order:2,
  name_en:'Official Documents',
  name_fr:'Official Documents',
  description_en:'Items from official documents. Pellentesque habitant morbi tristique senectus et netus et
  malesuada fames ac turpis egestas. Vestibulum tortor quam, feugiat vitae, ultricies eget, tempor sit
  amet, ante. Donec eu libero sit amet quam egestas semper. Aenean ultricies mi vitae est. Mauris placerat
  eleifend leo.',
  description_fr:'Items from official documents. In French',
  image_url:'https://stacks.stanford.edu/image/qv647nz8770/T0000001_thumb.jpg'
)
c3=CollectionHighlight.create(
  sort_order:3,
  name_en:'Personal Letters',
  name_fr:'Personal Letters',
  description_en:'Items from personal letters. Pellentesque habitant morbi tristique senectus et netus et
  malesuada fames ac turpis egestas. Vestibulum tortor quam, feugiat vitae, ultricies eget, tempor sit
  amet, ante. Donec eu libero sit amet quam egestas semper. Aenean ultricies mi vitae est. Mauris placerat
  eleifend leo.',
  description_fr:'Items from personal letters. In French',
  image_url:'https://stacks.stanford.edu/image/bb018fc7286/T0000001_thumb.jpg'
)

c1_items=%w{kb852bf7877 zp486wj7751 bb298qd7487 bb039cc5395}
c2_items=%w{qv647nz8770 bb204rc7778 zp486wj7751}
c3_items=%w{zp695fd1911 bb298qd7487 bb039cc5395 bb204rc7778}

add_items(c1_items,c1)
add_items(c2_items,c2)
add_items(c3_items,c3)
