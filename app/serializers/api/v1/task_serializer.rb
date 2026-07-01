# frozen_string_literal: true

module Api
  module V1
    class TaskSerializer < ApplicationSerializer
      view :list do
        {
          id: PublicTaskId.format(task_template_id: record.task_template_id, occurrence_date: record.occurrence_date),
          title: record.title,
          description: record.description,
          occurrence_date: serialize_date(record.occurrence_date),
          due_date: serialize_date(record.due_date),
          status: record.status,
          recurrence_type: record.task_template.recurrence_type,
          tags: serialize_tags
        }
      end

      view :detail do
        self.class.call(record, view: :list).merge(recurrence: serialize_recurrence)
      end

      private

      def serialize_tags
        return [] unless record.task_template.respond_to?(:tags)

        record.task_template.tags.map do |tag|
          {
            id: tag.id,
            name: tag.name,
            protected: tag.protected?
          }
        end
      end

      def serialize_recurrence
        return nil if record.task_template.once?

        {
          type: record.task_template.recurrence_type,
          interval: record.task_template.interval,
          end_date: serialize_date(record.task_template.end_date),
          day_of_month: record.task_template.day_of_month,
          specific_dates: record.task_template.specific_dates.map(&:iso8601),
          day_parity: record.task_template.day_parity
        }
      end
    end
  end
end
