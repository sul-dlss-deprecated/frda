# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130627175531) do

  create_table "bookmarks", :force => true do |t|
    t.integer  "user_id",     :null => false
    t.string   "document_id"
    t.string   "title"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "user_type"
  end

  create_table "category_ens", :force => true do |t|
    t.text     "name"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "position"
  end

  create_table "category_frs", :force => true do |t|
    t.text     "name"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "position"
  end

  create_table "collection_highlight_items", :force => true do |t|
    t.string   "item_id"
    t.integer  "collection_highlight_id"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  create_table "collection_highlights", :force => true do |t|
    t.string   "name_en"
    t.text     "description_en"
    t.string   "name_fr"
    t.text     "description_fr"
    t.string   "image_url"
    t.integer  "sort_order"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "political_periods", :force => true do |t|
    t.string   "name_en"
    t.string   "name_fr"
    t.string   "start_date"
    t.string   "end_date"
    t.integer  "sort_order"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "searches", :force => true do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.string   "user_type"
  end

  add_index "searches", ["user_id"], :name => "index_searches_on_user_id"

  create_table "sqlite_sp_functions", :id => false, :force => true do |t|
    t.text "name"
    t.text "text"
  end

# Could not dump table "sqlite_stat1" because of following StandardError
#   Unknown type '' for column 'tbl'

# Could not dump table "sqlite_stat3" because of following StandardError
#   Unknown type '' for column 'tbl'

  create_table "sqlite_vs_links_names", :id => false, :force => true do |t|
    t.text "name"
    t.text "alias"
  end

  create_table "sqlite_vs_properties", :id => false, :force => true do |t|
    t.text "parentType"
    t.text "parentName"
    t.text "propertyName"
    t.text "propertyValue"
  end

  create_table "sqlite_vsp_diagrams", :id => false, :force => true do |t|
    t.text "name"
    t.text "diadata"
    t.text "comment"
    t.text "preview"
  end

  create_table "users", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
