# frozen_string_literal: true

module Api
  module V1
    module TagContract
      class Name < ApplicationContract
        params do
          required(:name).filled(:string)
        end

        rule(:name) do
          key.failure("has already been taken") if Tag.exists?(name: value)
        end
      end

      class UpdateName < ApplicationContract
        params do
          required(:id).filled(:integer)
          required(:name).filled(:string)
        end

        rule(:id) do
          ensure_record(:tag) { Tag.find_by(id: value) }
        end

        rule(:name) do
          next if values[:tag].blank?

          key.failure("has already been taken") if Tag.where(name: value).where.not(id: values[:tag].id).exists?
        end
      end

      class Id < ApplicationContract
        params do
          required(:id).filled(:integer)
        end

        rule(:id) do
          ensure_record(:tag) { Tag.find_by(id: value) }
        end
      end

      class TaskTags < ApplicationContract
        params do
          required(:tag_ids).array(:integer)
        end

        rule(:tag_ids) do
          missing_ids = value.uniq - Tag.where(id: value).pluck(:id)
          key.failure("include missing tags: #{missing_ids.join(", ")}") if missing_ids.any?
        end
      end
    end
  end
end
