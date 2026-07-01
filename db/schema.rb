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

ActiveRecord::Schema[8.0].define(version: 2026_06_30_000200) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "protected", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "task_template_tags", force: :cascade do |t|
    t.bigint "task_template_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_task_template_tags_on_tag_id"
    t.index ["task_template_id", "tag_id"], name: "index_task_template_tags_on_task_template_id_and_tag_id", unique: true
    t.index ["task_template_id"], name: "index_task_template_tags_on_task_template_id"
  end

  create_table "task_templates", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "recurrence_type", null: false
    t.date "start_date", null: false
    t.date "end_date"
    t.bigint "previous_template_id"
    t.integer "interval"
    t.integer "day_of_month"
    t.date "specific_dates", default: [], null: false, array: true
    t.string "day_parity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["previous_template_id"], name: "index_task_templates_on_previous_template_id"
    t.index ["recurrence_type"], name: "index_task_templates_on_recurrence_type"
    t.index ["start_date", "end_date"], name: "index_task_templates_on_start_date_and_end_date"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "task_template_id", null: false
    t.date "occurrence_date", null: false
    t.date "due_date", null: false
    t.string "title", null: false
    t.text "description"
    t.string "status", null: false
    t.string "materialization_reason", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_tasks_on_discarded_at"
    t.index ["due_date"], name: "index_tasks_on_due_date"
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["task_template_id", "occurrence_date"], name: "index_tasks_on_task_template_id_and_occurrence_date", unique: true
    t.index ["task_template_id"], name: "index_tasks_on_task_template_id"
  end

  add_foreign_key "task_template_tags", "tags"
  add_foreign_key "task_template_tags", "task_templates"
  add_foreign_key "task_templates", "task_templates", column: "previous_template_id"
  add_foreign_key "tasks", "task_templates"
end
