class AddPositionToCategoryEn < ActiveRecord::Migration
  def change
    add_column :category_ens, :position, :string
  end
end
