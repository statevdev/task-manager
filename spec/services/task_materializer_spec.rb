# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskMaterializer do
  it "materializes virtual occurrence idempotently" do
    template = TaskTemplate.create!(title: "Daily round", recurrence_type: :daily, start_date: "2026-07-01", interval: 1)

    first = described_class.call(
      task_template: template,
      occurrence_date: Date.new(2026, 7, 2),
      attributes: { status: "completed" },
      materialization_reason: "status_change"
    )
    second = described_class.call(
      task_template: template,
      occurrence_date: Date.new(2026, 7, 2),
      attributes: { status: "completed" },
      materialization_reason: "status_change"
    )

    expect(second.id).to eq(first.id)
    expect(Task.count).to eq(1)
    expect(second.status).to eq("completed")
  end
end
