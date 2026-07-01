# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::QaEdgeCases", type: :request do
  it "updates tags through PATCH for a one-time task" do
    tag = Tag.create!(name: "priority")
    task = Api::V1::TaskCreateForm.call(title: "Call patient", due_date: "2026-07-01").result
    public_id = PublicTaskId.format(task_template_id: task.task_template_id, occurrence_date: task.occurrence_date)

    patch "/api/v1/tasks/#{public_id}", params: { tag_ids: [ tag.id ] }, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "tags").map { |item| item.fetch("id") }).to eq([ tag.id ])
  end

  it "rejects recurrence updates for one-time tasks instead of silently ignoring them" do
    task = Api::V1::TaskCreateForm.call(title: "Call patient", due_date: "2026-07-01").result
    public_id = PublicTaskId.format(task_template_id: task.task_template_id, occurrence_date: task.occurrence_date)

    patch "/api/v1/tasks/#{public_id}", params: {
      recurrence: { type: "daily", interval: 1 }
    }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("errors").to_s).to include("recurrence")
  end

  it "rejects empty recurrence patches for recurring tasks instead of creating an identical successor" do
    post "/api/v1/tasks", params: {
      title: "Daily round",
      due_date: "2026-07-01",
      recurrence: { type: "daily", interval: 1, end_date: "2026-07-03" }
    }, as: :json
    template_id = response.parsed_body.dig("data", "id").split("_")[1]

    patch "/api/v1/tasks/tpl_#{template_id}_2026-07-02", params: { recurrence: {} }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(TaskTemplate.find(template_id).successor_templates).to be_empty
  end

  it "rejects effective_date-only patches for recurring tasks instead of creating an identical successor" do
    post "/api/v1/tasks", params: {
      title: "Daily round",
      due_date: "2026-07-01",
      recurrence: { type: "daily", interval: 1, end_date: "2026-07-03" }
    }, as: :json
    template_id = response.parsed_body.dig("data", "id").split("_")[1]

    patch "/api/v1/tasks/tpl_#{template_id}_2026-07-02", params: { effective_date: "2026-07-02" }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(TaskTemplate.find(template_id).successor_templates).to be_empty
  end

  it "returns not found when removing a tag id that does not exist" do
    task = Api::V1::TaskCreateForm.call(title: "Call patient", due_date: "2026-07-01").result
    public_id = PublicTaskId.format(task_template_id: task.task_template_id, occurrence_date: task.occurrence_date)

    delete "/api/v1/tasks/#{public_id}/tags/123456"

    expect(response).to have_http_status(:not_found)
  end

  it "returns the first generated monthly occurrence when due_date is only the series start date" do
    post "/api/v1/tasks", params: {
      title: "Inventory",
      due_date: "2026-07-01",
      recurrence: { type: "monthly", day_of_month: 15 }
    }, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.dig("data", "id")).to match(/\Atpl_\d+_2026-07-15\z/)
    expect(response.parsed_body.dig("data", "due_date")).to eq("2026-07-15")
  end

  it "returns the first explicit date when due_date is only the series start date" do
    post "/api/v1/tasks", params: {
      title: "Reports",
      due_date: "2026-07-01",
      recurrence: { type: "specific_dates", specific_dates: [ "2026-07-03" ] }
    }, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.dig("data", "id")).to match(/\Atpl_\d+_2026-07-03\z/)
    expect(response.parsed_body.dig("data", "due_date")).to eq("2026-07-03")
  end

  it "returns the first matching parity date when due_date is only the series start date" do
    post "/api/v1/tasks", params: {
      title: "Reports",
      due_date: "2026-07-01",
      recurrence: { type: "day_parity", day_parity: "even" }
    }, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.dig("data", "id")).to match(/\Atpl_\d+_2026-07-02\z/)
    expect(response.parsed_body.dig("data", "due_date")).to eq("2026-07-02")
  end

  it "rejects recurrence rules that generate no occurrences after due_date" do
    post "/api/v1/tasks", params: {
      title: "Reports",
      due_date: "2026-07-01",
      recurrence: { type: "specific_dates", specific_dates: [ "2026-06-30" ] }
    }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("errors").to_s).to include("at least one occurrence")
  end

  it "rejects irrelevant recurrence parameters instead of silently ignoring them" do
    post "/api/v1/tasks", params: {
      title: "Reports",
      due_date: "2026-07-01",
      recurrence: {
        type: "daily",
        interval: 1,
        day_of_month: 15
      }
    }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("errors").to_s).to include("day_of_month")
  end
end
