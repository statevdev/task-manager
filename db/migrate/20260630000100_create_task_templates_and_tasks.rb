# frozen_string_literal: true

class CreateTaskTemplatesAndTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :task_templates do |t|
      t.string :title, null: false
      t.text :description
      t.string :recurrence_type, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.references :previous_template, foreign_key: { to_table: :task_templates }
      t.integer :interval
      t.integer :day_of_month
      t.date :specific_dates, array: true, default: [], null: false
      t.string :day_parity

      t.timestamps
    end

    add_index :task_templates, :recurrence_type
    add_index :task_templates, %i[start_date end_date]

    create_table :tasks do |t|
      t.references :task_template, null: false, foreign_key: true
      t.date :occurrence_date, null: false
      t.date :due_date, null: false
      t.string :title, null: false
      t.text :description
      t.string :status, null: false
      t.string :materialization_reason, null: false
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :tasks, %i[task_template_id occurrence_date], unique: true
    add_index :tasks, :due_date
    add_index :tasks, :status
    add_index :tasks, :discarded_at
  end
end
