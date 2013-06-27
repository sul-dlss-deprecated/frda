# -*- encoding : utf-8 -*-

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# -- Start Images Catalog Headings --
#    1. Query Solr to get catalog_heading for each Images item
#    2. Keep only distinct catalog headings
#       Format: The events of the Revolution -- Everyday politics -- Demonstrations
#    3. For each distinct heading, use ' -- ' to split string into tokens
#    4. Store tokens in hash of hashes so each level is a key pointing to child level hash
#    5. Go through keys and store each level in database, with pointer to parent id

def add_string(headings_array, str)
  headings_array.push(str)
end

# Put tokens into hash so each level is key to nested child level hash
def collect_words(stored_data, words)
  return stored_data if words.length == 0
  w = words.shift
  stored_data[w] ||= {}
  stored_data[w] = collect_words(stored_data[w],words)
  stored_data
end

# Store in database, using parent_id to create tree structure
def store_words(data, parent_id, lang)
  category_model = "Category#{lang}".constantize # there are separate En and Fr versions of model
  return if data.keys.length == 0
  data.keys.each do |k|
    # puts "name = #{k}, parent_id = #{parent_id}"
    # Case statement is for storing desired display order of the three top-level categories
    case k
    when 'The events of the Revolution', 'Les événements de la Révolution'
      pos = '1'
    when 'Themes in art and culture', 'Aspects culturels et artistiques'
      pos = '2'
    when 'Archives and documents', 'Archives et documents'
      pos = '3'
    else
      pos = '99'
    end
    cm = category_model.create!(:name => k, :parent_id => parent_id, :position => pos)
    store_words(data[k], cm.id,lang)
  end
end

# Query solr to get catalog_heading for all Images items
def get_catalog_headings(lang)
  lang == 'en' ? facet = 'catalog_heading_etsimv' : facet = 'catalog_heading_ftsimv'
  headings = Blacklight.solr.select(:params => {
    :fq     => 'collection_ssi:"Images de la Révolution française"',
    :rows   => '30000',
    :fl     => "#{facet}",
    :hl     => false
  })
  # store each heading in array
  headings_array = []
  headings['response']['docs'].each do |heading|
    array = heading.values
    array.each do |v|
      v = v[0]
      if !v.is_a? String
        puts "v is a #{v.class}: "
      else
        # puts "v is a string: #{v}"
        headings_array << v
      end
    end
  end
  unique_headings = headings_array.uniq     # remove duplicates
  unique_headings.reject! { |h| h.empty? }  # remove blank headings
  return unique_headings
end

# Split up each catalog heading into tokens and store in database as tree structure
def store_catalog_headings(unique_headings, lang)
  stored_data = {}
  heading_records = []
  unique_headings.each do |heading|
    re = Regexp.new(/\s--\s/) # break up using ' -- ' as delimiter
    chars = heading.split("")
    words = []
    index = 0
    chars.each_with_index do |c,i|
      test = chars[i..i+3].join('')
      if re.match(test)
        word = chars[index..i-1].join('')
        # puts "word = #{word}"
        words.push(word)
        index = i+4
      end
    end
    words.push(chars[index..-1].join('')) # now have array of level elements
    stored_data = collect_words(stored_data, words)
  end
  return stored_data
end

# Call methods to process and store catalog headings for given language
def seed_catalog_headings(lang)
  "Category#{lang}".constantize.delete_all
  unique_headings_locale = get_catalog_headings(lang.downcase) # get headings for locale
  puts "\nTotal number of unique #{lang} catalog headings: #{unique_headings_locale.length}\n"
  words_to_store = store_catalog_headings(unique_headings_locale, lang)
  store_words(words_to_store, nil, lang)
end

seed_catalog_headings('En')
seed_catalog_headings('Fr')
#-- end Images Catalog Headings --

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
