# frozen_string_literal: true

module Api
  module V1
    class TaskCreateForm < ApplicationForm
      def call
        validation = validate_with(TaskCreateContract.new)
        return self if validation.failure?

        attributes = validation.to_h

        ActiveRecord::Base.transaction do
          template = TaskTemplate.create!(template_attributes(attributes))
          template.tag_ids = attributes[:tag_ids] if attributes[:tag_ids].present?

          assign_result(attributes[:recurrence].present? ? virtual_instance(template) : create_once_task(template, attributes))
        end

        self
      rescue ActiveRecord::RecordInvalid => e
        @errors = e.record.errors.to_hash
        self
      end

      private

      def template_attributes(attributes)
        recurrence = attributes[:recurrence]
        return once_template_attributes(attributes) if recurrence.blank?

        {
          title: attributes.fetch(:title),
          description: attributes[:description],
          recurrence_type: recurrence.fetch(:type),
          start_date: attributes.fetch(:due_date),
          end_date: recurrence[:end_date],
          interval: recurrence[:interval],
          day_of_month: recurrence[:day_of_month],
          specific_dates: Array(recurrence[:specific_dates]).map(&:to_date).uniq.sort,
          day_parity: recurrence[:day_parity]
        }
      end

      def once_template_attributes(attributes)
        {
          title: attributes.fetch(:title),
          description: attributes[:description],
          recurrence_type: :once,
          start_date: attributes.fetch(:due_date)
        }
      end

      def create_once_task(template, attributes)
        template.tasks.create!(
          occurrence_date: attributes.fetch(:due_date),
          due_date: attributes.fetch(:due_date),
          title: attributes.fetch(:title),
          description: attributes[:description],
          status: attributes[:status].presence || :pending,
          materialization_reason: :once
        )
      end

      def virtual_instance(template)
        TaskInstance.new(task_template: template, occurrence_date: first_occurrence_date(template))
      end

      def first_occurrence_date(template)
        Recurrence::FirstOccurrenceDate.call(
          start_date: template.start_date,
          recurrence_type: template.recurrence_type,
          end_date: template.end_date,
          interval: template.interval,
          day_of_month: template.day_of_month,
          specific_dates: template.specific_dates,
          day_parity: template.day_parity
        )
      end
    end
  end
end
