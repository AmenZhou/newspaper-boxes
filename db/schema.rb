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

ActiveRecord::Schema.define(version: 20160416154430) do

  create_table "epoch_branches", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "histories", force: true do |t|
    t.integer  "newspaper"
    t.integer  "box"
    t.string   "borough"
    t.integer  "zipcode"
    t.string   "city"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "city_sum"
    t.integer  "borough_sum"
    t.integer  "zip_sum"
    t.string   "box_type"
    t.integer  "epoch_branch_id"
  end

  create_table "imports", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "newspaper_bases", force: true do |t|
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.integer  "zip"
    t.string   "borough_detail"
    t.string   "address_remark"
    t.datetime "date_t"
    t.string   "deliver_type"
    t.text     "remark"
    t.integer  "iron_box"
    t.integer  "plastic_box"
    t.integer  "selling_box"
    t.integer  "paper_shelf"
    t.integer  "mon",                        default: 0
    t.integer  "tue",                        default: 0
    t.integer  "wed",                        default: 0
    t.integer  "thu",                        default: 0
    t.integer  "fri",                        default: 0
    t.integer  "sat",                        default: 0
    t.integer  "sun",                        default: 0
    t.float    "latitude",        limit: 24
    t.float    "longitude",       limit: 24
    t.float    "sort_num",        limit: 24
    t.boolean  "trash",                      default: false
    t.string   "building"
    t.string   "type"
    t.string   "place_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "epoch_branch_id"
    t.boolean  "new_box_flg",                default: false
  end

  add_index "newspaper_bases", ["epoch_branch_id"], name: "index_newspaper_bases_on_epoch_branch_id", using: :btree

  create_table "newspaper_boxes", force: true do |t|
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.integer  "zip"
    t.string   "borough_detail"
    t.text     "address_remark"
    t.datetime "date_t"
    t.string   "deliver_type"
    t.text     "remark"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "iron_box"
    t.integer  "plastic_box"
    t.integer  "selling_box"
    t.integer  "paper_shelf"
    t.integer  "mon",                       default: 0
    t.integer  "tue",                       default: 0
    t.integer  "wed",                       default: 0
    t.integer  "thu",                       default: 0
    t.integer  "fri",                       default: 0
    t.integer  "sat",                       default: 0
    t.integer  "sun",                       default: 0
    t.float    "latitude",       limit: 24
    t.float    "longitude",      limit: 24
    t.float    "sort_num",       limit: 24
    t.boolean  "trash",                     default: false
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "role"
    t.integer  "epoch_branch_id"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["epoch_branch_id"], name: "index_users_on_epoch_branch_id", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
