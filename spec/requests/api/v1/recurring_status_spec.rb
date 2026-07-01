# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::RecurringStatus", type: :request do
  it "completes one recurring occurrence without affecting adjacent dates" do
    post "/api/v1/tasks", params: {
      title: "Daily round",
      due_date: "2026-07-01",
      recurrence: { type: "daily", interval: 1, end_date: "2026-07-03" }
    }, as: :json

    expect(response).to have_http_status(:created)
    template_id = response.parsed_body.dig("data", "id").split("_")[1]
    occurrence_id = "tpl_#{template_id}_2026-07-02"

    patch "/api/v1/tasks/#{occurrence_id}", params: { status: "completed" }, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "status")).to eq("completed")
    expect(Task.count).to eq(1)

    get "/api/v1/tasks", params: { from: "2026-07-01", to: "2026-07-03" }

    expect(response).to have_http_status(:ok)
    statuses = response.parsed_body.fetch("data").to_h { |task| [ task.fetch("due_date"), task.fetch("status") ] }
    expect(statuses).to eq(
      {
        "2026-07-01" => "pending",
        "2026-07-02" => "completed",
        "2026-07-03" => "pending"
      }
    )
  end
end
