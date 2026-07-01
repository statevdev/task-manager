# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::TaskUpdateForm do
  it "materializes a virtual occurrence on status change" do
    template = TaskTemplate.create!(title: "Daily round", recurrence_type: :daily, start_date: "2026-07-01", interval: 1)
    public_id = PublicTaskId.format(task_template_id: template.id, occurrence_date: Date.new(2026, 7, 2))

    form = described_class.call(id: public_id, status: "completed")

    expect(form).to be_valid
    expect(form.result.status).to eq("completed")
    expect(form.result.occurrence_date).to eq(Date.new(2026, 7, 2))
    expect(Task.count).to eq(1)
  end
end
