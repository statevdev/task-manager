# frozen_string_literal: true

module Api
  module V1
    class TaskIndexContract < ApplicationContract
      params do
        required(:from).filled(:date)
        required(:to).filled(:date)
        optional(:status).array(:string)
        optional(:tag_ids).array(:integer)
      end

      rule(:to) do
        next if values[:from].blank? || value.blank?

        key.failure(:date_order?) if value < values[:from]
        key.failure(:bounded_date_window?) if (value - values[:from]).to_i > 365
      end

      rule(:status).each do
        key.failure("must be pending, completed, or canceled") if value.present? && Task::STATUSES.values.exclude?(value)
      end
    end
  end
end
