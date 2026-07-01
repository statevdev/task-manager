# frozen_string_literal: true

module Api
  module V1
    class TaskSeriesController < ApplicationController
      def destroy
        form = TaskSeriesCloseForm.call(id: params[:task_id])

        if form.valid?
          render_data(TaskSerializer.call(form.result, view: :detail))
        else
          render_errors(form.errors, status: form.error_status || :unprocessable_entity)
        end
      end
    end
  end
end
