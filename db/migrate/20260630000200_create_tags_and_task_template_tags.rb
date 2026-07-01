# frozen_string_literal: true

class CreateTagsAndTaskTemplateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.boolean :protected, null: false, default: false

      t.timestamps
    end

    add_index :tags, :name, unique: true

    create_table :task_template_tags do |t|
      t.references :task_template, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :task_template_tags, %i[task_template_id tag_id], unique: true
  end
end
