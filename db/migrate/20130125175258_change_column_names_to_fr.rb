class ChangeColumnNamesToFr < ActiveRecord::Migration
  def self.up
    rename_column :collection_highlights, :name_it, :name_fr
    rename_column :collection_highlights, :description_it, :description_fr
  end

  def self.down
    rename_column :collection_highlights, :name_fr, :name_it
    rename_column :collection_highlights, :description_fr, :description_it
  end
end
