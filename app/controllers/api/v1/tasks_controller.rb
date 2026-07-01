# frozen_string_literal: true

module Api
  module V1
    class TasksController < ApplicationController
      def index
        form = TaskIndexForm.call(task_index_params)

        if form.valid?
          render_data(TaskSerializer.call(form.result, view: :list))
        else
          render_errors(form.errors)
        end
      end

      def show
        form = TaskShowForm.call(id: params[:id])

        if form.valid?
          render_data(TaskSerializer.call(form.result, view: :detail))
        else
          render_errors(form.errors, status: form.error_status || :unprocessable_entity)
        end
      end

      def create
        form = TaskCreateForm.call(task_create_params)

        if form.valid?
          render_data(TaskSerializer.call(form.result, view: :detail), status: :created)
        else
          render_errors(form.errors)
        end
      end

      def update
        form = TaskUpdateForm.call(task_update_params.merge(id: params[:id]))

        if form.valid?
          render_data(TaskSerializer.call(form.result, view: :detail))
        else
          render_errors(form.errors, status: form.error_status || :unprocessable_entity)
        end
      end

      def destroy
        form = TaskDeleteForm.call(id: params[:id])

        if form.valid?
          head :no_content
        else
          render_errors(form.errors, status: form.error_status || :unprocessable_entity)
        end
      end

      private

      def task_create_params
        params.permit(:title, :description, :due_date, :status, tag_ids: [], recurrence: {}).to_h
      end

      def task_update_params
        params.permit(:title, :description, :due_date, :status, :effective_date, tag_ids: [], recurrence: {}).to_h
      end

      def task_index_params
        params.permit(:from, :to, status: [], tag_ids: []).to_h
      end
    end
  end
end
