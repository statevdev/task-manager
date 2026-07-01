# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::RecurringSeriesUpdate", type: :request do
  it "applies recurring PATCH changes prospectively through a successor template" do
    original_tag = Tag.create!(name: "rounds")
    new_tag = Tag.create!(name: "priority")

    post "/api/v1/tasks", params: {
      title: "Daily round",
      due_date: "2026-06-29",
      tag_ids: [ original_tag.id ],
      recurrence: { type: "daily", interval: 1, end_date: "2026-07-05" }
    }, as: :json

    template_id = response.parsed_body.dig("data", "id").split("_")[1]

    patch "/api/v1/tasks/tpl_#{template_id}_2026-07-01", params: {
      title: "Updated round",
      tag_ids: [ new_tag.id ],
      effective_date: "2026-07-02",
      recurrence: { type: "daily", interval: 2, end_date: "2026-07-07" }
    }, as: :json

    expect(response).to have_http_status(:ok)

    original = TaskTemplate.find(template_id)
    successor = original.successor_templates.sole
    expect(original.end_date).to eq(Date.new(2026, 7, 1))
    expect(successor.start_date).to eq(Date.new(2026, 7, 2))
    expect(successor.title).to eq("Updated round")
    expect(successor.interval).to eq(2)
    expect(successor.end_date).to eq(Date.new(2026, 7, 7))
    expect(successor.tags).to eq([ new_tag ])

    get "/api/v1/tasks", params: { from: "2026-07-01", to: "2026-07-05" }

    expect(response).to have_http_status(:ok)
    tasks = response.parsed_body.fetch("data")
    expect(tasks.map { |task| [ task.fetch("due_date"), task.fetch("title") ] }).to eq(
      [
        [ "2026-07-01", "Daily round" ],
        [ "2026-07-02", "Updated round" ],
        [ "2026-07-04", "Updated round" ]
      ]
    )
  end

  it "rejects recurring PATCH changes after the series end date" do
    post "/api/v1/tasks", params: {
      title: "Daily round",
      due_date: "2026-07-01",
      recurrence: { type: "daily", interval: 1, end_date: "2026-07-03" }
    }, as: :json

    template_id = response.parsed_body.dig("data", "id").split("_")[1]

    patch "/api/v1/tasks/tpl_#{template_id}_2026-07-02", params: {
      title: "Late update",
      effective_date: "2026-07-04"
    }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("errors").to_s).to include("series end_date")
    expect(TaskTemplate.find(template_id).successor_templates).to be_empty
  end
end
