class ChangeDataTypeForCatalogHeadingString < ActiveRecord::Migration
  def up
    remove_column :catalog_headings, :name_en
    remove_column :catalog_headings, :name_fr

    add_column :catalog_headings, :name_en, :text
    add_column :catalog_headings, :name_fr, :text
  end

  def down
    remove_column :catalog_headings, :name_en
    remove_column :catalog_headings, :name_fr

    add_column :catalog_headings, :name_en, :string
    add_column :catalog_headings, :name_fr, :string
  end
end
