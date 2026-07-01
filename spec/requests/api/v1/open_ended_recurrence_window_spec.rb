# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::OpenEndedRecurrenceWindow", type: :request do
  it "lists a 90-day open-ended recurring task window without precreating tasks" do
    post "/api/v1/tasks", params: {
      title: "Daily round",
      due_date: "2026-07-01",
      recurrence: { type: "daily", interval: 1 }
    }, as: :json

    expect(response).to have_http_status(:created)
    expect(Task.count).to eq(0)

    get "/api/v1/tasks", params: { from: "2026-07-01", to: "2026-09-28" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").size).to eq(90)
    expect(Task.count).to eq(0)
  end
end
