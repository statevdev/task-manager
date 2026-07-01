# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::TaskSerializer do
  it "serializes compact and detail one-time task responses" do
    task = Api::V1::TaskCreateForm.call(title: "Call patient", due_date: "2026-07-01").result

    compact = described_class.call(task, view: :list)
    detail = described_class.call(task, view: :detail)

    expect(compact.fetch(:id)).to eq(PublicTaskId.format(task_template_id: task.task_template_id, occurrence_date: task.occurrence_date))
    expect(compact.fetch(:recurrence_type)).to eq("once")
    expect(compact.fetch(:tags)).to eq([])
    expect(detail.fetch(:recurrence)).to be_nil
  end
end
