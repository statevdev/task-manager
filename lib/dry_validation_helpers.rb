# frozen_string_literal: true

module DryValidationHelpers
  def merge_results(root, result)
    root_path = Array(root)

    result.errors.each do |error|
      key([ *root_path, *error.path ]).failure(error.text)
    end

    root_path.present? ? values.dig(*root_path).merge!(result.to_h) : values.merge!(result.to_h)
  end

  def ensure_record(field_name = nil)
    record = yield

    if record
      values[field_name] = record if field_name
    else
      key.failure(:record_exists?)
    end

    record
  end

  def yield_value_or_array
    return unless value

    if value.is_a?(Array)
      value.each_with_index { |item, index| yield([ *keys, index ], item) }
    else
      yield(keys, value)
    end
  end
end
