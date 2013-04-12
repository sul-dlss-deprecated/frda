# -*- encoding : utf-8 -*-

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


# query Solr, get Images catalog headings for one language, remove duplicates, store in array
def get_catalog_headings(lang)
  lang == 'en' ? facet = 'catalog_heading_etsimv' : facet = 'catalog_heading_ftsimv'
  headings = Blacklight.solr.select(:params => {
    :fq     => 'collection_ssi:"Images de la Révolution française"',
    :rows   => '30000',
    :fl     => "#{facet}",
    :hl     => false
  })
  headings_array = []
  headings['response']['docs'].each do |heading|
     heading.each_value { |val| headings_array << val }
  end
  unique_headings = headings_array.uniq     # remove duplicates
  unique_headings.reject! { |h| h.empty? }  # remove blank headings
  return unique_headings
end

# break up each catalog heading into level components and store in database as tree structure
def store_catalog_headings(unique_headings, lang)
  unique_headings.each do |heading|
    category_model = "Category#{lang}".constantize # there are separate En and Fr versions of model
    re = Regexp.new(/\s--\s/) # break up using ' -- ' as delimiter
    chars = heading.join("").split("")
    words = []
    index = 0
    chars.each_with_index do |c,i|
      test = chars[i..i+3].join('')

      if re.match(test)
        words.push(chars[index..i-1].join(''))
        index = i+4
      end
    end
    words.push(chars[index..-1].join('')) # now have array of level elements

    root_node = category_model.create!(:name => words[0]) # store first-level

    unless words[1].nil?
      first_child = category_model.create!(:name => words[1]) # store second-level
      first_child.move_to_child_of(root_node)
    end

    unless words[2].nil?
      second_child = category_model.create!(:name => words[2]) # store third-level
      second_child.move_to_child_of(first_child)
    end

    unless words[3].nil?
      third_child = category_model.create!(:name => words[3]) # store fourth-level
      third_child.move_to_child_of(second_child)
    end

  end
end

CategoryEn.delete_all
unique_headings_en = get_catalog_headings('en') # get English headings
puts "\nTotal number of unique English catalog headings: #{unique_headings_en.length}\n"
store_catalog_headings(unique_headings_en, 'En')

CategoryFr.delete_all
unique_headings_fr = get_catalog_headings('fr') # get French headings
puts "\nTotal number of unique French catalog headings: #{unique_headings_fr.length}\n"
store_catalog_headings(unique_headings_fr, 'Fr')

def add_items(items,coll)
  items.each {|item| coll.collection_highlight_items << CollectionHighlightItem.create(item_id:"#{item}")}
end

CollectionHighlight.find(:all).each {|h| h.destroy}
CollectionHighlightItem.find(:all).each {|hi| hi.destroy}
PoliticalPeriod.find(:all).each {|p| p.destroy}

c1=CollectionHighlight.create(
  sort_order:1,
  name_en:'University Correspondence',
  name_fr:'University Correspondance',
  description_en:'Items from university correspondance. Pellentesque habitant morbi tristique senectus et
  netus et malesuada fames ac turpis egestas. Vestibulum tortor quam, feugiat vitae, ultricies eget, tempor
  sit amet, ante. Donec eu libero sit amet quam egestas semper. Aenean ultricies mi vitae est. Mauris
  placerat eleifend leo.',
  description_fr:'Items from university correspondance. In French',
  image_url:'https://stacks.stanford.edu/image/bb298qd7487/T0000001_thumb.jpg'
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
  image_url:'https://stacks.stanford.edu/image/kb852bf7877/T0000001_thumb.jpg'
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
  image_url:'https://stacks.stanford.edu/image/qv647nz8770/T0000001_thumb.jpg'
)

c1_items=%w{qv647nz8770 zp486wj7751 bb298qd7487 bb039cc5395}
c2_items=%w{kb852bf7877 bb204rc7778 zp486wj7751}
c3_items=%w{zp695fd1911 bb298qd7487 bb039cc5395 bb204rc7778}

add_items(c1_items,c1)
add_items(c2_items,c2)
add_items(c3_items,c3)

PoliticalPeriod.create(
  sort_order:1,
  name_en: 'Assembly of Notables and preparation of Cahiers de doleances',
  name_fr: 'Assemblée de Notables et préparations pour les Cahiers de doléances',
  start_date: '1787-02-22',
  end_date: '1789-05-04'
)
PoliticalPeriod.create(
  sort_order:2,
  name_en: 'Gathering of Estates-General through fall of the Bastille',
  name_fr: 'Convocation des Etats-généraux et prise de la Bastille',
  start_date: '1789-05-05',
  end_date: '1789-07-14'
)
PoliticalPeriod.create(
  sort_order:3,
  name_en: 'Constituent Assembly',
  name_fr: 'Assemblée constituente',
  start_date: '1789-07-17',
  end_date: '1791-09-30'
)
PoliticalPeriod.create(
  sort_order:4,
  name_en: 'Legislative Assembly',
  name_fr: 'Assemblée législative',
  start_date: '1791-10-01',
  end_date: '1792-09-20'
)
PoliticalPeriod.create(
  sort_order:5,
  name_en: 'National Convention (until purge of Girondins)',
  name_fr: "Convention nationale (jusqu'a l'expulsion des girondins)",
  start_date: '1792-09-21',
  end_date: '1793-06-02'
)
PoliticalPeriod.create(
  sort_order:6,
  name_en: 'National Convention (until Thermidor)',
  name_fr: "Convention nationale (jusqu'a thermidor)",
  start_date: '1793-06-02',
  end_date: '1794-07-28'
)
PoliticalPeriod.create(
  sort_order:7,
  name_en: 'Thermidorian Convention',
  name_fr: 'Convention thermidorienne',
  start_date: '1794-07-28',
  end_date: '1795-10-26'
)
PoliticalPeriod.create(
  sort_order:8,
  name_en: 'First Directory',
  name_fr: 'Premier Directoire',
  start_date: '1795-10-27',
  end_date: '1797-09-04'
)
PoliticalPeriod.create(
  sort_order:9,
  name_en: 'Second Directory',
  name_fr: 'Seconde Directoire',
  start_date: '1797-09-04',
  end_date: '1799-06-18'
)
PoliticalPeriod.create(
  sort_order:10,
  name_en: "Third Directory and coup d'etat of 18 Brumaire",
  name_fr: "Troisième Directoire et coup d'état du 18 Brumaire",
  start_date: '1799-06-18',
  end_date: '1799-11-11'
)
