# frozen_string_literal: true

module Api
  module V1
    class TaskUpdateContract < ApplicationContract
      params do
        optional(:title).filled(:string)
        optional(:description).maybe(:string)
        optional(:due_date).filled(:date)
        optional(:status).filled(:string)
        optional(:tag_ids).array(:integer)
        optional(:recurrence).maybe(:hash) do
          optional(:type).filled(:string)
          optional(:interval).filled(:integer)
          optional(:end_date).filled(:date)
          optional(:day_of_month).filled(:integer)
          optional(:specific_dates).array(:date)
          optional(:day_parity).filled(:string)
        end
        optional(:effective_date).filled(:date)
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
        if type.present? && TaskTemplate::RECURRENCE_TYPES.except(:once).value?(type) == false
          key([ :recurrence, :type ]).failure("must be daily, monthly, specific_dates, or day_parity")
        end

        key([ :recurrence, :interval ]).failure("must be greater than 0") if value.key?(:interval) && !value[:interval].to_i.positive?
        key([ :recurrence, :day_of_month ]).failure("must be between 1 and 31") if value.key?(:day_of_month) && !value[:day_of_month].to_i.between?(1, 31)
        key([ :recurrence, :specific_dates ]).failure("must not include duplicate dates") if duplicate_dates?(value[:specific_dates])
        key([ :recurrence, :day_parity ]).failure("must be even or odd") if value[:day_parity].present? && TaskTemplate::DAY_PARITIES.value?(value[:day_parity]) == false
      end

      rule do
        key(:base).failure("must include at least one field") if values.except(:tag_ids).empty? && !values.key?(:tag_ids)
      end

      private

      def duplicate_dates?(dates)
        dates.present? && dates.uniq.size != dates.size
      end
    end
  end
end
