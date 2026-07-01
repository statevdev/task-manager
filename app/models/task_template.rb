# frozen_string_literal: true

class TaskTemplate < ApplicationRecord
  RECURRENCE_TYPES = {
    once: "once",
    daily: "daily",
    monthly: "monthly",
    specific_dates: "specific_dates",
    day_parity: "day_parity"
  }.freeze

  DAY_PARITIES = {
    even: "even",
    odd: "odd"
  }.freeze

  enum :recurrence_type, RECURRENCE_TYPES, validate: true
  enum :day_parity, DAY_PARITIES, prefix: true, validate: { allow_nil: true }

  belongs_to :previous_template, class_name: "TaskTemplate", optional: true
  has_many :successor_templates, class_name: "TaskTemplate", foreign_key: :previous_template_id, inverse_of: :previous_template, dependent: :nullify
  has_many :tasks, dependent: :restrict_with_exception
  has_many :task_template_tags, dependent: :destroy
  has_many :tags, through: :task_template_tags

  validates :title, :start_date, presence: true
  validate :end_date_is_not_before_start_date
  validate :recurrence_parameters_match_type
  validate :specific_dates_are_unique

  private

  def end_date_is_not_before_start_date
    return if start_date.blank? || end_date.blank? || end_date >= start_date

    errors.add(:end_date, "must be on or after start_date")
  end

  def recurrence_parameters_match_type
    case recurrence_type
    when "once"
      errors.add(:interval, "must be blank") if interval.present?
      errors.add(:day_of_month, "must be blank") if day_of_month.present?
      errors.add(:specific_dates, "must be blank") if specific_dates.present?
      errors.add(:day_parity, "must be blank") if day_parity.present?
    when "daily"
      errors.add(:interval, "must be greater than 0") unless interval.to_i.positive?
    when "monthly"
      errors.add(:day_of_month, "must be between 1 and 31") unless day_of_month.to_i.between?(1, 31)
    when "specific_dates"
      errors.add(:specific_dates, "must include at least one date") if specific_dates.blank?
    when "day_parity"
      errors.add(:day_parity, "must be even or odd") if day_parity.blank?
    end
  end

  def specific_dates_are_unique
    return if specific_dates.blank? || specific_dates.uniq.size == specific_dates.size

    errors.add(:specific_dates, "must not include duplicate dates")
  end
end
