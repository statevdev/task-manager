# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::TaskTagFiltering", type: :request do
  it "filters virtual and materialized task instances by tag ids" do
    call_tag = Tag.create!(name: "calls")
    report_tag = Tag.create!(name: "reports")

    post "/api/v1/tasks", params: {
      title: "Call patient",
      due_date: "2026-07-01",
      tag_ids: [ call_tag.id ]
    }, as: :json
    call_task_id = response.parsed_body.dig("data", "id")

    post "/api/v1/tasks", params: {
      title: "Daily report",
      due_date: "2026-07-01",
      tag_ids: [ report_tag.id ],
      recurrence: { type: "daily", interval: 1, end_date: "2026-07-02" }
    }, as: :json
    report_template_id = response.parsed_body.dig("data", "id").split("_")[1]

    get "/api/v1/tasks", params: {
      from: "2026-07-01",
      to: "2026-07-02",
      tag_ids: [ report_tag.id ]
    }

    expect(response).to have_http_status(:ok)
    ids = response.parsed_body.fetch("data").map { |task| task.fetch("id") }
    expect(ids).to eq(
      [
        "tpl_#{report_template_id}_2026-07-01",
        "tpl_#{report_template_id}_2026-07-02"
      ]
    )
    expect(ids).not_to include(call_task_id)
  end
end
