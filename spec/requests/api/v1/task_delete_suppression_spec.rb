# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::TaskDeleteSuppression", type: :request do
  it "deleting virtual occurrence creates discarded suppression marker" do
    post "/api/v1/tasks", params: {
      title: "Daily round",
      due_date: "2026-07-01",
      recurrence: { type: "daily", interval: 1, end_date: "2026-07-03" }
    }, as: :json

    template_id = response.parsed_body.dig("data", "id").split("_")[1]
    public_id = "tpl_#{template_id}_2026-07-02"

    delete "/api/v1/tasks/#{public_id}"
    expect(response).to have_http_status(:no_content)

    marker = Task.find_by!(task_template_id: template_id, occurrence_date: "2026-07-02")
    expect(marker).to be_discarded
    expect(marker.materialization_reason).to eq("delete")

    get "/api/v1/tasks", params: { from: "2026-07-01", to: "2026-07-03" }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").map { |task| task.fetch("id") }).not_to include(public_id)
  end
end
