# frozen_string_literal: true

class ApplicationContract < Dry::Validation::Contract
  module Predicates
    include Dry::Logic::Predicates

    predicate(:not_blank?) do |value|
      value.present?
    end

    predicate(:public_task_id?) do |value|
      value.is_a?(String) && value.match?(PublicTaskId::PATTERN)
    end

    predicate(:date_order?) do |value|
      value[:from].blank? || value[:to].blank? || value[:to] >= value[:from]
    end

    predicate(:bounded_date_window?) do |value|
      value[:from].blank? || value[:to].blank? || (value[:to] - value[:from]).to_i <= 365
    end
  end

  module Types
    include Dry::Types()
  end

  config.messages.backend = :yaml
  config.messages.default_locale = :en
  config.messages.load_paths << Rails.root.join("config/locales/dry_validation.en.yml")
  config.predicates = Predicates
end
