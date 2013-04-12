class CreateCategoryEns < ActiveRecord::Migration
  def change
    create_table :category_ens do |t|
      t.text :name
      t.integer :parent_id
      t.integer :lft
      t.integer :rgt

      t.timestamps
    end
  end
end
