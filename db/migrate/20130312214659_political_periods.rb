class PoliticalPeriods < ActiveRecord::Migration
  def up
    create_table :political_periods do |t|
      t.string :name_en
      t.string :name_fr
      t.string :start_date
      t.string :end_date
      t.integer :sort_order
      t.timestamps
    end
  end

  def down
    drop_table :political_periods
  end
end
