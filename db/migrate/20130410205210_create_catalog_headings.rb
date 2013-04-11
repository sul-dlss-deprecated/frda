class CreateCatalogHeadings < ActiveRecord::Migration
  def change
    create_table :catalog_headings do |t|
      t.string :name_en
      t.string :name_fr

      t.timestamps
    end
  end
end
