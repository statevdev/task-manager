# frozen_string_literal: true

module Api
  module V1
    class TaskSeriesCloseForm < ApplicationForm
      attr_reader :error_status

      def call
        validation = validate_with(TaskIdContract.new)
        return self if validation.failure?

        parsed = validation.to_h.fetch(:public_task_id)
        template = TaskTemplate.find_by(id: parsed.task_template_id)
        return not_found unless template
        return not_recurring if template.once?
        return not_found unless occurrence_exists?(template, parsed.occurrence_date)

        TaskTemplateCloser.call(template:)
        show_form = TaskShowForm.call(id: params[:id])

        if show_form.valid?
          assign_result(show_form.result)
        else
          assign_result(TaskInstance.new(task_template: template, occurrence_date: parsed.occurrence_date))
        end

        self
      end

      private

      def occurrence_exists?(template, occurrence_date)
        task = Task.find_by(task_template: template, occurrence_date:)
        return task.kept? if task

        window = Recurrence::OccurrenceWindow.call(from: occurrence_date, to: occurrence_date)
        Recurrence::OccurrenceGenerator.call(template:, window:).any? { |instance| instance.occurrence_date == occurrence_date }
      end

      def not_recurring
        @error_status = :unprocessable_entity
        @errors = { id: [ "must reference a recurring task" ] }
        self
      end

      def not_found
        @error_status = :not_found
        @errors = { id: [ "not found" ] }
        self
      end
    end
  end
end
