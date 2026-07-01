# frozen_string_literal: true

module Api
  module V1
    class TagForm < ApplicationForm
      attr_reader :error_status

      def call
        case params.fetch(:action).to_sym
        when :create then create
        when :update then update
        when :destroy then destroy
        else
          @errors = { action: [ "is invalid" ] }
        end

        self
      end

      private

      def create
        validation = TagContract::Name.new.call(params.slice(:name))
        return assign_errors(validation) if validation.failure?

        assign_result(Tag.create!(name: validation.to_h.fetch(:name)))
      rescue ActiveRecord::RecordInvalid => e
        @errors = e.record.errors.to_hash
      end

      def update
        validation = TagContract::UpdateName.new.call(params.slice(:id, :name))
        return assign_errors(validation) if validation.failure?

        tag = validation.to_h.fetch(:tag)
        return protected_tag if tag.protected?

        tag.update!(name: validation.to_h.fetch(:name))
        assign_result(tag)
      rescue ActiveRecord::RecordInvalid => e
        @errors = e.record.errors.to_hash
      end

      def destroy
        validation = TagContract::Id.new.call(params.slice(:id))
        return assign_errors(validation) if validation.failure?

        tag = validation.to_h.fetch(:tag)
        return protected_tag if tag.protected?

        tag.destroy!
        assign_result(tag)
      end

      def assign_errors(validation)
        @errors = validation.errors.to_h
      end

      def protected_tag
        @error_status = :forbidden
        @errors = { base: [ "protected tags cannot be changed" ] }
      end
    end
  end
end
