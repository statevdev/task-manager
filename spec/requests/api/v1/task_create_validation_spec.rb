# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::TaskCreateValidation", type: :request do
  it "rejects missing tag ids on create" do
    post "/api/v1/tasks", params: {
      title: "Call patient",
      due_date: "2026-07-01",
      tag_ids: [ 12_345 ]
    }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("errors").to_s).to include("missing tags")
  end

  it "rejects duplicate specific dates" do
    post "/api/v1/tasks", params: {
      title: "Reports",
      due_date: "2026-07-01",
      recurrence: {
        type: "specific_dates",
        specific_dates: [ "2026-07-03", "2026-07-03" ]
      }
    }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("errors").to_s).to include("duplicate dates")
  end

  it "rejects non-pending status for recurring task creation" do
    post "/api/v1/tasks", params: {
      title: "Daily round",
      due_date: "2026-07-01",
      status: "completed",
      recurrence: { type: "daily", interval: 1 }
    }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("errors").to_s).to include("must be pending")
  end
end
