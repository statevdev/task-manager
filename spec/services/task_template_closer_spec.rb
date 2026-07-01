# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskTemplateCloser do
  it "closes recurring series at current date and discards future materialized tasks" do
    travel_to Date.new(2026, 7, 1) do
      template = TaskTemplate.create!(title: "Daily round", recurrence_type: :daily, start_date: "2026-06-29", interval: 1)
      future = TaskMaterializer.call(
        task_template: template,
        occurrence_date: Date.new(2026, 7, 5),
        attributes: { status: "completed" },
        materialization_reason: "status_change"
      )

      described_class.call(template:)

      expect(template.reload.end_date).to eq(Date.new(2026, 7, 1))
      expect(future.reload).to be_discarded
    end
  end
end
