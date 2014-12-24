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

ActiveRecord::Schema.define(version: 20141106230807) do

  create_table "friendships", force: true do |t|
    t.integer  "friend_fb_id", limit: 8
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "friendships", ["friend_fb_id"], name: "index_friendships_on_friend_fb_id"
  add_index "friendships", ["user_id"], name: "index_friendships_on_user_id"

  create_table "guesses", force: true do |t|
    t.integer  "quiz_id"
    t.integer  "user_id"
    t.string   "answer"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "keyword_updates", force: true do |t|
    t.integer  "user_id"
    t.text     "removed"
    t.text     "comments"
    t.string   "uuid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "popularity", default: 0.0
    t.string   "keyword1"
    t.string   "keyword2"
    t.string   "keyword3"
  end

  create_table "keywords", force: true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "keyword"
  end

  create_table "keywords_users", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "keyword_id"
  end

  create_table "likes", force: true do |t|
    t.integer  "user_id"
    t.integer  "likee_id"
    t.integer  "keyword_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "quizzes", force: true do |t|
    t.string   "author"
    t.string   "keyword"
    t.string   "option0"
    t.string   "option1"
    t.string   "answer"
    t.string   "uuid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "comments"
    t.string   "author_name"
    t.string   "option0_name"
    t.string   "option1_name"
    t.integer  "keyword_id"
    t.float    "popularity",   default: 0.0
  end

  create_table "ranks", force: true do |t|
    t.integer  "user_id"
    t.integer  "keyword_id"
    t.integer  "score"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "statuses", force: true do |t|
    t.integer  "user_id"
    t.string   "status"
    t.text     "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid"
    t.float    "popularity", default: 0.0
  end

  create_table "users", force: true do |t|
    t.string  "name"
    t.string  "fb_id"
    t.string  "access_token"
    t.text    "logins"
    t.string  "device_token"
    t.integer "badge_number", default: 0
  end

end
