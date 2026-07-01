# frozen_string_literal: true

module Recurrence
  class OccurrenceWindow
    include Callable

    MAX_DAYS = 366

    attr_reader :from, :to

    def initialize(from:, to:)
      @from = from.to_date
      @to = to.to_date
    end

    def call
      raise ArgumentError, "to must be on or after from" if to < from
      raise ArgumentError, "window must be no longer than #{MAX_DAYS} days" if (to - from).to_i >= MAX_DAYS

      self
    end

    def range
      from..to
    end
  end
end
