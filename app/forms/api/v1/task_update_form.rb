# frozen_string_literal: true

module Api
  module V1
    class TaskUpdateForm < ApplicationForm
      attr_reader :error_status

      def call
        id_validation = TaskIdContract.new.call(id: params[:id])
        unless id_validation.success?
          @errors = id_validation.errors.to_h
          return self
        end

        validation = TaskUpdateContract.new.call(params.except(:id))
        unless validation.success?
          @errors = validation.errors.to_h
          return self
        end

        parsed = id_validation.to_h.fetch(:public_task_id)
        task = Task.find_by(task_template_id: parsed.task_template_id, occurrence_date: parsed.occurrence_date)
        template = task&.task_template || TaskTemplate.find_by(id: parsed.task_template_id)
        return not_found unless template

        attributes = validation.to_h
        return reject_once_series_fields(attributes) if once_series_fields?(template, attributes)
        return revise_template(template, parsed.occurrence_date, attributes) if series_revision?(template, attributes)

        return not_found if task&.discarded? && params[:status].blank?
        return materialize(parsed, attributes) unless task&.kept?

        update_attributes = attributes.slice(:title, :description, :due_date, :status)
        task.update!(update_attributes) if update_attributes.present?
        task.task_template.update!(update_attributes.slice(:title, :description, :due_date).transform_keys(due_date: :start_date)) if update_template?(task, update_attributes)
        task.task_template.update!(tag_ids: attributes[:tag_ids]) if update_once_tags?(task, attributes)

        assign_result(task)
        self
      rescue ActiveRecord::RecordInvalid => e
        @errors = e.record.errors.to_hash
        self
      end

      private

      def series_revision?(template, attributes)
        !template.once? && attributes.keys.intersect?(%i[recurrence tag_ids effective_date])
      end

      def once_series_fields?(template, attributes)
        template.once? && attributes.keys.intersect?(%i[recurrence effective_date])
      end

      def reject_once_series_fields(attributes)
        @error_status = :unprocessable_entity
        @errors = {}
        @errors[:recurrence] = [ "cannot be updated for one-time tasks" ] if attributes.key?(:recurrence)
        @errors[:effective_date] = [ "cannot be used for one-time tasks" ] if attributes.key?(:effective_date)
        self
      end

      def revise_template(template, occurrence_date, attributes)
        return not_found unless virtual_occurrence?(template, occurrence_date)

        successor = TaskTemplateReviser.call(
          template:,
          effective_date: attributes[:effective_date] || Date.current,
          attributes: revision_attributes(attributes)
        )

        assign_result(TaskInstance.new(task_template: successor, occurrence_date: successor.start_date))
        self
      end

      def revision_attributes(attributes)
        attributes
          .slice(:title, :description, :tag_ids)
          .merge(recurrence_attributes(attributes[:recurrence]))
          .compact
      end

      def recurrence_attributes(recurrence)
        return {} if recurrence.blank?

        {
          recurrence_type: recurrence[:type],
          end_date: recurrence[:end_date],
          interval: recurrence[:interval],
          day_of_month: recurrence[:day_of_month],
          specific_dates: recurrence[:specific_dates],
          day_parity: recurrence[:day_parity]
        }
      end

      def materialize(parsed, attributes)
        template = TaskTemplate.find_by(id: parsed.task_template_id)
        return not_found unless template && virtual_occurrence?(template, parsed.occurrence_date)

        task = TaskMaterializer.call(
          task_template: template,
          occurrence_date: parsed.occurrence_date,
          attributes: attributes.slice(:title, :description, :due_date, :status),
          materialization_reason: materialization_reason(parsed.occurrence_date, attributes)
        )

        assign_result(task)
        self
      end

      def virtual_occurrence?(template, occurrence_date)
        window = Recurrence::OccurrenceWindow.call(from: occurrence_date, to: occurrence_date)
        Recurrence::OccurrenceGenerator.call(template:, window:).any? { |instance| instance.occurrence_date == occurrence_date }
      end

      def materialization_reason(occurrence_date, attributes)
        return "move" if attributes[:due_date].present? && attributes[:due_date] != occurrence_date
        return "status_change" if attributes[:status].present?
        return "edit" if attributes.keys.intersect?(%i[title description])

        "manual"
      end

      def update_template?(task, attributes)
        task.task_template.once? && attributes.keys.intersect?(%i[title description due_date])
      end

      def update_once_tags?(task, attributes)
        task.task_template.once? && attributes.key?(:tag_ids)
      end

      def not_found
        @error_status = :not_found
        @errors = { id: [ "not found" ] }
        self
      end
    end
  end
end
