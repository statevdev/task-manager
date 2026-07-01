# frozen_string_literal: true

class TaskTemplateTag < ApplicationRecord
  belongs_to :task_template
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :task_template_id }
end
