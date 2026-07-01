# frozen_string_literal: true

module Recurrence
  class FirstOccurrenceDate
    include Callable

    def initialize(start_date:, recurrence_type:, end_date: nil, interval: nil, day_of_month: nil, specific_dates: [], day_parity: nil)
      @start_date = start_date.to_date
      @recurrence_type = recurrence_type.to_s
      @end_date = end_date&.to_date
      @interval = interval
      @day_of_month = day_of_month
      @specific_dates = Array(specific_dates)
      @day_parity = day_parity
    end

    def call
      candidate =
        case recurrence_type
        when "once", "daily" then daily_occurrence
        when "monthly" then monthly_occurrence
        when "specific_dates" then specific_date_occurrence
        when "day_parity" then day_parity_occurrence
        end

      return if candidate.blank?
      return if end_date.present? && candidate > end_date

      candidate
    end

    private

    attr_reader :start_date, :recurrence_type, :end_date, :interval, :day_of_month, :specific_dates, :day_parity

    def daily_occurrence
      start_date if recurrence_type == "once" || interval.to_i.positive?
    end

    def monthly_occurrence
      day = day_of_month.to_i
      return unless day.between?(1, 31)

      current = Date.new(start_date.year, start_date.month, 1)
      deadline = end_date || start_date.next_year
      last_month = Date.new(deadline.year, deadline.month, 1)

      while current <= last_month
        if Date.valid_date?(current.year, current.month, day)
          date = Date.new(current.year, current.month, day)
          return date if date >= start_date && (end_date.blank? || date <= end_date)
        end

        current = current.next_month
      end
    end

    def specific_date_occurrence
      specific_dates
        .map(&:to_date)
        .select { |date| date >= start_date && (end_date.blank? || date <= end_date) }
        .min
    end

    def day_parity_occurrence
      return unless TaskTemplate::DAY_PARITIES.value?(day_parity)

      expected_even = day_parity == "even"
      date = start_date
      deadline = end_date || start_date + 2.days

      while date <= deadline
        return date if date.day.even? == expected_even

        date += 1.day
      end
    end
  end
end
