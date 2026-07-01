# frozen_string_literal: true

class Task < ApplicationRecord
  include Discard::Model

  STATUSES = {
    pending: "pending",
    completed: "completed",
    canceled: "canceled"
  }.freeze

  MATERIALIZATION_REASONS = {
    once: "once",
    status_change: "status_change",
    move: "move",
    edit: "edit",
    delete: "delete",
    manual: "manual"
  }.freeze

  enum :status, STATUSES, validate: true
  enum :materialization_reason, MATERIALIZATION_REASONS, prefix: true, validate: true

  belongs_to :task_template

  validates :occurrence_date, :due_date, :title, :status, :materialization_reason, presence: true
  validates :occurrence_date, uniqueness: { scope: :task_template_id }

  scope :due_between, ->(from, to) { where(due_date: from..to) }
end
