class DropCatalogHeadings < ActiveRecord::Migration
  def up
    drop_table "catalog_headings"
  end
end
