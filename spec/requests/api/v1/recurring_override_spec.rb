# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::RecurringOverride", type: :request do
  it "cancels and moves one recurring occurrence" do
    post "/api/v1/tasks", params: {
      title: "Daily round",
      due_date: "2026-07-01",
      recurrence: { type: "daily", interval: 1, end_date: "2026-07-05" }
    }, as: :json

    template_id = response.parsed_body.dig("data", "id").split("_")[1]
    cancel_id = "tpl_#{template_id}_2026-07-02"
    move_id = "tpl_#{template_id}_2026-07-03"

    patch "/api/v1/tasks/#{cancel_id}", params: { status: "canceled" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "status")).to eq("canceled")

    patch "/api/v1/tasks/#{move_id}", params: { due_date: "2026-07-06" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "occurrence_date")).to eq("2026-07-03")
    expect(response.parsed_body.dig("data", "due_date")).to eq("2026-07-06")

    get "/api/v1/tasks", params: { from: "2026-07-03", to: "2026-07-03" }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data")).to be_empty

    get "/api/v1/tasks", params: { from: "2026-07-06", to: "2026-07-06" }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").map { |task| task.fetch("id") }).to eq([ move_id ])
  end
end
