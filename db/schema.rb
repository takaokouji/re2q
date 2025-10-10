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

ActiveRecord::Schema[8.0].define(version: 2025_10_10_101240) do
  create_table "admins", force: :cascade do |t|
    t.string "username", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username"], name: "index_admins_on_username", unique: true
  end

  create_table "answers", force: :cascade do |t|
    t.integer "player_id", null: false
    t.integer "question_id", null: false
    t.boolean "player_answer", null: false
    t.datetime "answered_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["answered_at"], name: "index_answers_on_answered_at"
    t.index ["player_id", "question_id"], name: "index_answers_on_player_id_and_question_id", unique: true
    t.index ["player_id"], name: "index_answers_on_player_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "current_quiz_states", force: :cascade do |t|
    t.integer "question_id"
    t.datetime "question_started_at"
    t.integer "duration_seconds"
    t.datetime "question_ends_at"
    t.string "persist_job_id"
    t.boolean "quiz_active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_current_quiz_states_on_id", unique: true
  end

  create_table "final_rankings", force: :cascade do |t|
    t.integer "player_id", null: false
    t.integer "rank", null: false
    t.integer "correct_count", default: 0, null: false
    t.integer "total_answered", default: 0, null: false
    t.integer "lottery_score", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_final_rankings_on_player_id"
  end

  create_table "players", force: :cascade do |t|
    t.string "uuid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_players_on_uuid", unique: true
  end

  create_table "questions", force: :cascade do |t|
    t.text "content", null: false
    t.boolean "correct_answer", null: false
    t.integer "duration_seconds", default: 15, null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_questions_on_position", unique: true
  end

  add_foreign_key "answers", "players"
  add_foreign_key "answers", "questions"
  add_foreign_key "current_quiz_states", "questions"
  add_foreign_key "final_rankings", "players"
end
