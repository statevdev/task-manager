# frozen_string_literal: true

class TaskMaterializer
  include Callable

  def initialize(task_template:, occurrence_date:, attributes: {}, materialization_reason: "manual")
    @task_template = task_template
    @occurrence_date = occurrence_date.to_date
    @attributes = attributes.symbolize_keys
    @materialization_reason = materialization_reason
  end

  def call
    Task.transaction do
      task = Task.lock.find_by(task_template:, occurrence_date:)
      task ||= task_template.tasks.build(occurrence_date:)

      apply_attributes(task)
      task.undiscard! if task.persisted? && task.discarded?
      task.save!
      task
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  private

  attr_reader :task_template, :occurrence_date, :attributes, :materialization_reason

  def apply_attributes(task)
    task.assign_attributes(
      due_date: attributes[:due_date] || task.due_date || occurrence_date,
      title: attributes[:title] || task.title || task_template.title,
      description: attributes.key?(:description) ? attributes[:description] : (task.description || task_template.description),
      status: attributes[:status] || task.status || "pending",
      materialization_reason: normalized_reason
    )
  end

  def normalized_reason
    return materialization_reason if Task::MATERIALIZATION_REASONS.value?(materialization_reason)

    "manual"
  end
end
