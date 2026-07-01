# frozen_string_literal: true

module Recurrence
  class OccurrenceGenerator
    include Callable

    def initialize(template:, window:)
      @template = template
      @window = window
    end

    def call
      dates.map do |date|
        TaskInstance.new(task_template: template, occurrence_date: date)
      end
    end

    private

    attr_reader :template, :window

    def dates
      case template.recurrence_type
      when "once" then once_dates
      when "daily" then daily_dates
      when "monthly" then monthly_dates
      when "specific_dates" then specific_dates
      when "day_parity" then day_parity_dates
      else []
      end
    end

    def effective_range
      start_date = [ template.start_date, window.from ].max
      end_date = [ template.end_date || window.to, window.to ].min
      return nil if end_date < start_date

      start_date..end_date
    end

    def once_dates
      return [] unless effective_range&.cover?(template.start_date)

      [ template.start_date ]
    end

    def daily_dates
      return [] unless effective_range

      interval = template.interval.to_i
      effective_range.select do |date|
        ((date - template.start_date).to_i % interval).zero?
      end
    end

    def monthly_dates
      return [] unless effective_range

      months_between(effective_range.begin, effective_range.end).filter_map do |year, month|
        next unless Date.valid_date?(year, month, template.day_of_month)

        date = Date.new(year, month, template.day_of_month)
        date if effective_range.cover?(date)
      end
    end

    def specific_dates
      return [] unless effective_range

      template.specific_dates.map(&:to_date).uniq.sort.select { |date| effective_range.cover?(date) }
    end

    def day_parity_dates
      return [] unless effective_range

      expected_even = template.day_parity == "even"
      effective_range.select { |date| date.day.even? == expected_even }
    end

    def months_between(from, to)
      current = Date.new(from.year, from.month, 1)
      last = Date.new(to.year, to.month, 1)
      months = []

      while current <= last
        months << [ current.year, current.month ]
        current = current.next_month
      end

      months
    end
  end
end
