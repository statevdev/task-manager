# frozen_string_literal: true

module Api
  module V1
    class TaskIdContract < ApplicationContract
      params do
        required(:id).filled(:string)
      end

      rule(:id) do
        parsed = PublicTaskId.parse(value)

        if parsed
          values[:public_task_id] = parsed
        else
          key.failure(:public_task_id?)
        end
      end
    end
  end
end
