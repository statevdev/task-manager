# frozen_string_literal: true

module Api
  module V1
    class TaskShowForm < ApplicationForm
      attr_reader :error_status

      def call
        validation = validate_with(TaskIdContract.new)
        return self if validation.failure?

        parsed = validation.to_h.fetch(:public_task_id)
        task = Task.find_by(task_template_id: parsed.task_template_id, occurrence_date: parsed.occurrence_date)

        if task&.kept?
          assign_result(task)
        elsif task&.discarded?
          not_found
        elsif virtual_occurrence = find_virtual_occurrence(parsed)
          assign_result(virtual_occurrence)
        else
          not_found
        end

        self
      end

      private

      def find_virtual_occurrence(parsed)
        template = TaskTemplate.find_by(id: parsed.task_template_id)
        return unless template

        window = Recurrence::OccurrenceWindow.call(from: parsed.occurrence_date, to: parsed.occurrence_date)
        Recurrence::OccurrenceGenerator.call(template:, window:).find { |instance| instance.occurrence_date == parsed.occurrence_date }
      end

      def not_found
        @error_status = :not_found
        @errors = { id: [ "not found" ] }
      end
    end
  end
end
