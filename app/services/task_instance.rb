# frozen_string_literal: true

class TaskInstance
  attr_reader :task_template, :occurrence_date, :due_date

  def initialize(task_template:, occurrence_date:, due_date: occurrence_date)
    @task_template = task_template
    @occurrence_date = occurrence_date
    @due_date = due_date
  end

  def task_template_id
    task_template.id
  end

  def title
    task_template.title
  end

  def description
    task_template.description
  end

  def status
    "pending"
  end

  def kept?
    true
  end

  def discarded?
    false
  end

  def materialized?
    false
  end
end
