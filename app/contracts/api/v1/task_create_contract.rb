# frozen_string_literal: true

module Api
  module V1
    class TaskCreateContract < ApplicationContract
      params do
        required(:title).filled(:string)
        optional(:description).maybe(:string)
        required(:due_date).filled(:date)
        optional(:status).maybe(:string)
        optional(:tag_ids).array(:integer)
        optional(:recurrence).maybe(:hash) do
          required(:type).filled(:string)
          optional(:interval).filled(:integer)
          optional(:end_date).filled(:date)
          optional(:day_of_month).filled(:integer)
          optional(:specific_dates).array(:date)
          optional(:day_parity).filled(:string)
        end
      end

      rule(:status) do
        key.failure("must be pending, completed, or canceled") if value.present? && Task::STATUSES.values.exclude?(value)
      end

      rule(:tag_ids) do
        next if value.blank?

        missing_ids = value.uniq - Tag.where(id: value).pluck(:id)
        key.failure("include missing tags: #{missing_ids.join(", ")}") if missing_ids.any?
      end

      rule(:recurrence) do
        next if value.blank?

        type = value[:type]
        unless TaskTemplate::RECURRENCE_TYPES.except(:once).value?(type)
          key(:recurrence).failure("type must be daily, monthly, specific_dates, or day_parity")
          next
        end

        irrelevant_recurrence_keys(type, value).each do |key_name|
          key([ :recurrence, key_name ]).failure("must be blank for #{type} recurrence")
        end

        case type
        when "daily"
          key([ :recurrence, :interval ]).failure("is required") unless value[:interval].to_i.positive?
        when "monthly"
          key([ :recurrence, :day_of_month ]).failure("must be between 1 and 31") unless value[:day_of_month].to_i.between?(1, 31)
        when "specific_dates"
          key([ :recurrence, :specific_dates ]).failure("must include at least one date") if value[:specific_dates].blank?
          key([ :recurrence, :specific_dates ]).failure("must not include duplicate dates") if duplicate_dates?(value[:specific_dates])
        when "day_parity"
          key([ :recurrence, :day_parity ]).failure("must be even or odd") unless TaskTemplate::DAY_PARITIES.value?(value[:day_parity])
        end

        key([ :recurrence, :end_date ]).failure("must be on or after due_date") if value[:end_date].present? && values[:due_date].present? && value[:end_date] < values[:due_date]
        key(:recurrence).failure("must generate at least one occurrence on or after due_date") if values[:due_date].present? && recurrence_generates_no_dates?(values[:due_date], value)
        key(:status).failure("must be pending or omitted for recurring tasks") if values[:status].present? && values[:status] != "pending"
      end

      private

      def duplicate_dates?(dates)
        dates.present? && dates.uniq.size != dates.size
      end

      def irrelevant_recurrence_keys(type, recurrence)
        allowed_keys = {
          "daily" => %i[type interval end_date],
          "monthly" => %i[type day_of_month end_date],
          "specific_dates" => %i[type specific_dates end_date],
          "day_parity" => %i[type day_parity end_date]
        }.fetch(type)

        recurrence.keys.select { |key_name| allowed_keys.exclude?(key_name) && recurrence[key_name].present? }
      end

      def recurrence_generates_no_dates?(due_date, recurrence)
        Recurrence::FirstOccurrenceDate.call(
          start_date: due_date,
          recurrence_type: recurrence[:type],
          end_date: recurrence[:end_date],
          interval: recurrence[:interval],
          day_of_month: recurrence[:day_of_month],
          specific_dates: recurrence[:specific_dates],
          day_parity: recurrence[:day_parity]
        ).blank?
      end
    end
  end
end
