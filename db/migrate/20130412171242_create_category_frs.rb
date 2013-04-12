class CreateCategoryFrs < ActiveRecord::Migration
  def change
    create_table :category_frs do |t|
      t.text :name
      t.integer :parent_id
      t.integer :lft
      t.integer :rgt

      t.timestamps
    end
  end
end
