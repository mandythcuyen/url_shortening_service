# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_15_183634) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "short_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "original_url", null: false
    t.string "original_url_hash", limit: 64, null: false
    t.string "session_token", null: false
    t.string "short_code", limit: 10, null: false
    t.datetime "updated_at", null: false
    t.index ["session_token", "original_url_hash"], name: "index_short_links_on_session_token_and_original_url_hash", unique: true
    t.index ["short_code"], name: "index_short_links_on_short_code", unique: true
  end
end
