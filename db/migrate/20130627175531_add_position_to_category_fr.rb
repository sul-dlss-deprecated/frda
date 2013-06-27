class AddPositionToCategoryFr < ActiveRecord::Migration
  def change
    add_column :category_frs, :position, :string
  end
end
