# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::RecurringTasks", type: :request do
  it "creates recurring template without precreating future tasks and lists virtual occurrences" do
    post "/api/v1/tasks", params: {
      title: "Daily round",
      description: "Visit patients",
      due_date: "2026-07-01",
      recurrence: {
        type: "daily",
        interval: 1,
        end_date: "2026-07-03"
      }
    }, as: :json

    expect(response).to have_http_status(:created)
    created = response.parsed_body.fetch("data")
    expect(created.fetch("id")).to match(/\Atpl_\d+_2026-07-01\z/)
    expect(created.dig("recurrence", "type")).to eq("daily")
    expect(Task.count).to eq(0)

    get "/api/v1/tasks", params: { from: "2026-07-01", to: "2026-07-05" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").map { |task| task.fetch("due_date") }).to eq(%w[2026-07-01 2026-07-02 2026-07-03])
    expect(response.parsed_body.fetch("data").map { |task| task.fetch("status") }.uniq).to eq([ "pending" ])
  end
end
