# frozen_string_literal: true

# Keep API date coercion strict; Date.parse accepts partial garbage.
strict_params_date = Dry::Types["nominal.date"].constructor do |value|
  case value
  when Date then value
  else Date.iso8601(value.to_s)
  end
end

Dry::Types.container.instance_variable_get(:@_container).delete("params.date")
Dry::Types.container.register("params.date", strict_params_date)
