# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::TaskSeriesClose", type: :request do
  it "closes a recurring series for an existing virtual occurrence" do
    travel_to Date.new(2026, 7, 1) do
      post "/api/v1/tasks", params: {
        title: "Daily round",
        due_date: "2026-06-29",
        recurrence: { type: "daily", interval: 1, end_date: "2026-07-05" }
      }, as: :json

      template_id = response.parsed_body.dig("data", "id").split("_")[1]

      delete "/api/v1/tasks/tpl_#{template_id}_2026-07-01/series"

      expect(response).to have_http_status(:ok)
      expect(TaskTemplate.find(template_id).end_date).to eq(Date.new(2026, 7, 1))
    end
  end

  it "rejects closing a recurring series through an impossible occurrence id" do
    travel_to Date.new(2026, 7, 1) do
      post "/api/v1/tasks", params: {
        title: "Daily round",
        due_date: "2026-07-01",
        recurrence: { type: "daily", interval: 1, end_date: "2026-07-03" }
      }, as: :json

      template_id = response.parsed_body.dig("data", "id").split("_")[1]

      delete "/api/v1/tasks/tpl_#{template_id}_2026-07-10/series"

      expect(response).to have_http_status(:not_found)
      expect(TaskTemplate.find(template_id).end_date).to eq(Date.new(2026, 7, 3))
    end
  end

  it "rejects series close for a one-time task" do
    post "/api/v1/tasks", params: {
      title: "Call patient",
      due_date: "2026-07-01"
    }, as: :json

    task_id = response.parsed_body.dig("data", "id")

    delete "/api/v1/tasks/#{task_id}/series"

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("errors").to_s).to include("recurring")
  end
end
