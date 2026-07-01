# frozen_string_literal: true

module Api
  module V1
    class TagSerializer < ApplicationSerializer
      view :default do
        {
          id: record.id,
          name: record.name,
          protected: record.protected?
        }
      end
    end
  end
end
