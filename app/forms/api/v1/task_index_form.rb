# frozen_string_literal: true

require "set"

module Api
  module V1
    class TaskIndexForm < ApplicationForm
      def call
        validation = validate_with(TaskIndexContract.new)
        return self if validation.failure?

        attributes = validation.to_h
        window = Recurrence::OccurrenceWindow.call(from: attributes.fetch(:from), to: attributes.fetch(:to))
        tasks = overlay_instances(window).select { |task| window.range.cover?(task.due_date) }
        tasks = tasks.select { |task| attributes[:status].include?(task.status) } if attributes[:status].present?
        tasks = tasks.select { |task| tagged_with_any?(task, attributes[:tag_ids]) } if attributes[:tag_ids].present?

        assign_result(tasks.sort_by { |task| [ task.due_date, task.task_template_id ] })
        self
      end

      private

      def overlay_instances(window)
        templates = candidate_templates(window)
        materialized = materialized_by_key(templates, window)
        virtual_keys = Set.new

        overlaid = templates.flat_map do |template|
          Recurrence::OccurrenceGenerator.call(template:, window:).filter_map do |virtual_instance|
            virtual_keys << overlay_key(virtual_instance.task_template_id, virtual_instance.occurrence_date)
            materialized_task = materialized[overlay_key(virtual_instance.task_template_id, virtual_instance.occurrence_date)]

            if materialized_task&.kept?
              materialized_task
            elsif materialized_task&.discarded?
              nil
            else
              virtual_instance
            end
          end
        end

        moved_or_extra = materialized.values.select do |task|
          task.kept? && window.range.cover?(task.due_date) && virtual_keys.exclude?(overlay_key(task.task_template_id, task.occurrence_date))
        end

        overlaid + moved_or_extra
      end

      def materialized_by_key(templates, window)
        ids = templates.map(&:id)
        return {} if ids.empty?

        Task
          .includes(task_template: :tags)
          .where(task_template_id: ids)
          .where("occurrence_date BETWEEN :from AND :to OR due_date BETWEEN :from AND :to", from: window.from, to: window.to)
          .index_by { |task| overlay_key(task.task_template_id, task.occurrence_date) }
      end

      def candidate_templates(window)
        active = TaskTemplate
          .includes(:tags)
          .where("start_date <= ?", window.to)
          .where("end_date IS NULL OR end_date >= ?", window.from)

        materialized_template_ids = Task
          .where("occurrence_date BETWEEN :from AND :to OR due_date BETWEEN :from AND :to", from: window.from, to: window.to)
          .select(:task_template_id)

        (active.to_a + TaskTemplate.includes(:tags).where(id: materialized_template_ids).to_a).uniq.sort_by(&:id)
      end

      def overlay_key(task_template_id, occurrence_date)
        "#{task_template_id}:#{occurrence_date.iso8601}"
      end

      def tagged_with_any?(task, tag_ids)
        (task.task_template.tag_ids & tag_ids).any?
      end
    end
  end
end
