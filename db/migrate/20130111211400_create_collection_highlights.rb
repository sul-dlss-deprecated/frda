class CreateCollectionHighlights < ActiveRecord::Migration
  def change
    create_table :collection_highlights do |t|
      t.string :name_en
      t.text :description_en
      t.string :name_it
      t.text :description_it
      t.string :image_url
      t.integer :sort_order
      t.timestamps
    end
  end
end
