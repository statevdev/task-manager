# frozen_string_literal: true

module Api
  module V1
    class ApplicationController < ActionController::API
      private

      def render_data(payload, status: :ok)
        render json: { data: payload }, status: status
      end

      def render_errors(errors, status: :unprocessable_entity)
        render json: { errors: normalize_errors(errors) }, status: status
      end

      def render_not_found(message = "Not found")
        render_errors([ { detail: message } ], status: :not_found)
      end

      def normalize_errors(errors)
        return errors.to_h if errors.respond_to?(:to_h)

        errors
      end
    end
  end
end
