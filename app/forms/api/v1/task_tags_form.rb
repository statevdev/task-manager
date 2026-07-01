# frozen_string_literal: true

module Api
  module V1
    class TaskTagsForm < ApplicationForm
      attr_reader :error_status

      def call
        case params.fetch(:action).to_sym
        when :attach then attach
        when :remove then remove
        else
          @errors = { action: [ "is invalid" ] }
        end

        self
      end

      private

      def attach
        task = resolve_task
        return self unless task

        validation = TagContract::TaskTags.new.call(params.slice(:tag_ids))
        return assign_errors(validation) if validation.failure?

        tag_ids = task.task_template.tag_ids | validation.to_h.fetch(:tag_ids)
        assign_result(apply_tag_ids(task, tag_ids))
      end

      def remove
        task = resolve_task
        return self unless task

        tag_id = Integer(params[:tag_id], exception: false)
        return tag_not_found unless tag_id && Tag.exists?(id: tag_id)

        tag_ids = task.task_template.tag_ids - [ tag_id ]
        assign_result(apply_tag_ids(task, tag_ids))
      end

      def resolve_task
        id_validation = TaskIdContract.new.call(id: params[:id])
        return assign_errors(id_validation) if id_validation.failure?

        parsed = id_validation.to_h.fetch(:public_task_id)
        task = Task.kept.find_by(task_template_id: parsed.task_template_id, occurrence_date: parsed.occurrence_date)
        return task if task

        template = TaskTemplate.find_by(id: parsed.task_template_id)
        return not_found unless template

        window = Recurrence::OccurrenceWindow.call(from: parsed.occurrence_date, to: parsed.occurrence_date)
        virtual = Recurrence::OccurrenceGenerator.call(template:, window:).find { |instance| instance.occurrence_date == parsed.occurrence_date }
        return not_found unless virtual

        virtual
      end

      def apply_tag_ids(task, tag_ids)
        return apply_once_tag_ids(task, tag_ids) if task.task_template.once?

        successor = TaskTemplateReviser.call(
          template: task.task_template,
          effective_date: Date.current,
          attributes: { tag_ids: }
        )
        TaskInstance.new(task_template: successor, occurrence_date: successor.start_date)
      end

      def apply_once_tag_ids(task, tag_ids)
        task.task_template.tag_ids = tag_ids
        task.reload
      end

      def assign_errors(validation)
        @errors = validation.errors.to_h
        nil
      end

      def not_found
        @error_status = :not_found
        @errors = { id: [ "not found" ] }
        nil
      end

      def tag_not_found
        @error_status = :not_found
        @errors = { tag_id: [ "not found" ] }
        nil
      end
    end
  end
end
