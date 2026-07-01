# frozen_string_literal: true

module Api
  module V1
    class TagsController < ApplicationController
      def index
        render_data(TagSerializer.call(Tag.order(:name)))
      end

      def create
        form = TagForm.call(tag_params.merge(action: :create))

        if form.valid?
          render_data(TagSerializer.call(form.result), status: :created)
        else
          render_errors(form.errors, status: form.error_status || :unprocessable_entity)
        end
      end

      def update
        form = TagForm.call(tag_params.merge(id: params[:id], action: :update))

        if form.valid?
          render_data(TagSerializer.call(form.result))
        else
          render_errors(form.errors, status: form.error_status || :unprocessable_entity)
        end
      end

      def destroy
        form = TagForm.call(id: params[:id], action: :destroy)

        if form.valid?
          head :no_content
        else
          render_errors(form.errors, status: form.error_status || :unprocessable_entity)
        end
      end

      private

      def tag_params
        params.permit(:name).to_h
      end
    end
  end
end
