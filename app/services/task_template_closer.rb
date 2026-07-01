# frozen_string_literal: true

class TaskTemplateCloser
  include Callable

  def initialize(template:, close_date: Date.current)
    @template = template
    @close_date = close_date
  end

  def call
    TaskTemplate.transaction do
      template.update!(end_date: close_date)
      template.tasks.kept.where("due_date > ?", close_date).find_each(&:discard!)
      template
    end
  end

  private

  attr_reader :template, :close_date
end
