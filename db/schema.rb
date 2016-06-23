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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20130627175531) do

  create_table "bookmarks", force: :cascade do |t|
    t.integer  "user_id",                 null: false
    t.string   "document_id", limit: 255
    t.string   "title",       limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.string   "user_type",   limit: 255
  end

  create_table "category_ens", force: :cascade do |t|
    t.text     "name"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "position",   limit: 255
  end

  create_table "category_frs", force: :cascade do |t|
    t.text     "name"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "position",   limit: 255
  end

  create_table "collection_highlight_items", force: :cascade do |t|
    t.string   "item_id",                 limit: 255
    t.integer  "collection_highlight_id"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  create_table "collection_highlights", force: :cascade do |t|
    t.string   "name_en",        limit: 255
    t.text     "description_en"
    t.string   "name_fr",        limit: 255
    t.text     "description_fr"
    t.string   "image_url",      limit: 255
    t.integer  "sort_order"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "political_periods", force: :cascade do |t|
    t.string   "name_en",    limit: 255
    t.string   "name_fr",    limit: 255
    t.string   "start_date", limit: 255
    t.string   "end_date",   limit: 255
    t.integer  "sort_order"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "searches", force: :cascade do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "user_type",    limit: 255
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id"

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
