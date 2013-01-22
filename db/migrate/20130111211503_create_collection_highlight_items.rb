class CreateCollectionHighlightItems < ActiveRecord::Migration
  def change
    create_table :collection_highlight_items do |t|
      t.string :item_id
      t.integer :collection_highlight_id
      t.timestamps
    end
  end
end
