# frozen_string_literal: true

module Api
  module V1
    class TaskDeleteForm < ApplicationForm
      attr_reader :error_status

      def call
        validation = validate_with(TaskIdContract.new)
        return self if validation.failure?

        parsed = validation.to_h.fetch(:public_task_id)
        task = Task.find_by(task_template_id: parsed.task_template_id, occurrence_date: parsed.occurrence_date)
        return discard_task(task) if task

        template = TaskTemplate.find_by(id: parsed.task_template_id)
        return not_found unless template && virtual_occurrence?(template, parsed.occurrence_date)

        task = TaskMaterializer.call(
          task_template: template,
          occurrence_date: parsed.occurrence_date,
          attributes: { status: "pending" },
          materialization_reason: "delete"
        )
        discard_task(task)
        self
      end

      private

      def discard_task(task)
        task.discard! unless task.discarded?
        assign_result(task)
        self
      end

      def virtual_occurrence?(template, occurrence_date)
        window = Recurrence::OccurrenceWindow.call(from: occurrence_date, to: occurrence_date)
        Recurrence::OccurrenceGenerator.call(template:, window:).any? { |instance| instance.occurrence_date == occurrence_date }
      end

      def not_found
        @error_status = :not_found
        @errors = { id: [ "not found" ] }
        self
      end
    end
  end
end
