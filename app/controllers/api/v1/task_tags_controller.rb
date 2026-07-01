# frozen_string_literal: true

module Api
  module V1
    class TaskTagsController < ApplicationController
      def create
        form = TaskTagsForm.call(id: params[:task_id], tag_ids: task_tags_params[:tag_ids], action: :attach)

        if form.valid?
          render_data(TaskSerializer.call(form.result, view: :detail))
        else
          render_errors(form.errors, status: form.error_status || :unprocessable_entity)
        end
      end

      def destroy
        form = TaskTagsForm.call(id: params[:task_id], tag_id: params[:id], action: :remove)

        if form.valid?
          render_data(TaskSerializer.call(form.result, view: :detail))
        else
          render_errors(form.errors, status: form.error_status || :unprocessable_entity)
        end
      end

      private

      def task_tags_params
        params.permit(tag_ids: []).to_h
      end
    end
  end
end
