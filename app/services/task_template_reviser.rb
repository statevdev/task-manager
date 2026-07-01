# frozen_string_literal: true

class TaskTemplateReviser
  include Callable

  def initialize(template:, effective_date:, attributes: {})
    @template = template
    @effective_date = effective_date.to_date
    @attributes = attributes.symbolize_keys
    @original_end_date = template.end_date
  end

  def call
    TaskTemplate.transaction do
      if effective_date <= template.start_date
        template.update!(revision_attributes(template).merge(start_date: template.start_date))
        apply_tags(template)
        template
      else
        close_current_template
        successor = template.class.create!(revision_attributes(template).merge(start_date: effective_date, previous_template: template))
        apply_tags(successor)
        discard_future_materialized
        successor
      end
    end
  end

  private

  attr_reader :template, :effective_date, :attributes

  def close_current_template
    if template.end_date.present? && effective_date > template.end_date
      template.errors.add(:effective_date, "must be on or before series end_date")
      raise ActiveRecord::RecordInvalid, template
    end

    template.update!(end_date: effective_date - 1.day)
  end

  def revision_attributes(source)
    normalized_recurrence_attributes(
      title: attributes.fetch(:title, source.title),
      description: attributes.key?(:description) ? attributes[:description] : source.description,
      recurrence_type: attributes.fetch(:recurrence_type, source.recurrence_type),
      end_date: attributes.fetch(:end_date, original_end_date),
      interval: attributes.fetch(:interval, source.interval),
      day_of_month: attributes.fetch(:day_of_month, source.day_of_month),
      specific_dates: attributes.fetch(:specific_dates, source.specific_dates),
      day_parity: attributes.fetch(:day_parity, source.day_parity)
    )
  end

  def normalized_recurrence_attributes(revision)
    case revision.fetch(:recurrence_type).to_s
    when "daily"
      revision.merge(day_of_month: nil, specific_dates: [], day_parity: nil)
    when "monthly"
      revision.merge(interval: nil, specific_dates: [], day_parity: nil)
    when "specific_dates"
      revision.merge(interval: nil, day_of_month: nil, specific_dates: Array(revision[:specific_dates]).map(&:to_date).uniq.sort, day_parity: nil)
    when "day_parity"
      revision.merge(interval: nil, day_of_month: nil, specific_dates: [])
    else
      revision.merge(interval: nil, day_of_month: nil, specific_dates: [], day_parity: nil)
    end
  end

  def apply_tags(target)
    target.tag_ids = attributes.key?(:tag_ids) ? attributes[:tag_ids] : template.tag_ids
  end

  def discard_future_materialized
    template.tasks.kept.where("due_date > ?", template.end_date).find_each(&:discard!)
  end

  attr_reader :original_end_date
end
