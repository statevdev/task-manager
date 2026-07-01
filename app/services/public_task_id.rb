# frozen_string_literal: true

class PublicTaskId
  include Callable

  PATTERN = /\Atpl_(?<task_template_id>\d+)_(?<occurrence_date>\d{4}-\d{2}-\d{2})\z/

  Parsed = Struct.new(:task_template_id, :occurrence_date, keyword_init: true)

  def self.format(task_template_id:, occurrence_date:)
    "tpl_#{task_template_id}_#{occurrence_date.to_date.iso8601}"
  end

  def self.parse(value)
    match = PATTERN.match(value.to_s)
    return unless match

    Parsed.new(
      task_template_id: match[:task_template_id].to_i,
      occurrence_date: Date.iso8601(match[:occurrence_date])
    )
  rescue Date::Error
    nil
  end

  def initialize(task_template_id:, occurrence_date:)
    @task_template_id = task_template_id
    @occurrence_date = occurrence_date
  end

  def call
    self.class.format(task_template_id:, occurrence_date:)
  end

  private

  attr_reader :task_template_id, :occurrence_date
end
