# frozen_string_literal: true

class ApplicationForm
  include ActiveModel::Model
  include Callable

  attr_reader :errors, :result

  def initialize(params = {})
    @params = params.to_h.deep_symbolize_keys
    @errors = {}
  end

  def call
    raise NotImplementedError, "#{self.class.name} must implement #call"
  end

  def valid?
    errors.blank?
  end

  private

  attr_reader :params

  def validate_with(contract)
    validation = contract.call(params)
    @errors = validation.errors.to_h
    validation
  end

  def assign_result(value)
    @result = value
  end
end
