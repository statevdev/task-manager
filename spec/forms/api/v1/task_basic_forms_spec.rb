# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 task basic forms" do
  it "create form creates template and physical task" do
    form = Api::V1::TaskCreateForm.call(
      title: "Prepare report",
      description: "Quarterly numbers",
      due_date: "2026-07-01"
    )

    expect(form).to be_valid
    expect(TaskTemplate.count).to eq(1)
    expect(Task.count).to eq(1)
    expect(form.result.task_template).to eq(TaskTemplate.first)
    expect(form.result.occurrence_date).to eq(Date.new(2026, 7, 1))
  end

  it "delete form discards task and show form returns not found" do
    task = Api::V1::TaskCreateForm.call(title: "Call patient", due_date: "2026-07-01").result
    public_id = PublicTaskId.format(task_template_id: task.task_template_id, occurrence_date: task.occurrence_date)

    delete_form = Api::V1::TaskDeleteForm.call(id: public_id)

    expect(delete_form).to be_valid
    expect(task.reload).to be_discarded

    show_form = Api::V1::TaskShowForm.call(id: public_id)

    expect(show_form).not_to be_valid
    expect(show_form.error_status).to eq(:not_found)
  end
end
