# frozen_string_literal: true

require Rails.root.join("lib/dry_validation_helpers")

Dry::Validation::Evaluator.include(DryValidationHelpers)
