# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::VirtualTaskTags", type: :request do
  it "adds tags to a virtual recurring occurrence prospectively" do
    travel_to Date.new(2026, 7, 1) do
      tag = Tag.create!(name: "priority")

      post "/api/v1/tasks", params: {
        title: "Daily round",
        due_date: "2026-06-29",
        recurrence: { type: "daily", interval: 1, end_date: "2026-07-03" }
      }, as: :json
      template_id = response.parsed_body.dig("data", "id").split("_")[1]

      post "/api/v1/tasks/tpl_#{template_id}_2026-07-01/tags", params: { tag_ids: [ tag.id ] }, as: :json

      expect(response).to have_http_status(:ok)

      original = TaskTemplate.find(template_id)
      successor = original.successor_templates.sole
      expect(original.end_date).to eq(Date.new(2026, 6, 30))
      expect(successor.tags).to eq([ tag ])
      expect(response.parsed_body.dig("data", "id")).to eq("tpl_#{successor.id}_2026-07-01")

      get "/api/v1/tasks", params: { from: "2026-06-30", to: "2026-07-01" }

      tasks_by_date = response.parsed_body.fetch("data").index_by { |task| task.fetch("due_date") }
      expect(tasks_by_date.fetch("2026-06-30").fetch("tags")).to eq([])
      expect(tasks_by_date.fetch("2026-07-01").fetch("tags").map { |item| item.fetch("id") }).to eq([ tag.id ])
    end
  end

  it "removes tags from a virtual recurring occurrence prospectively" do
    travel_to Date.new(2026, 7, 1) do
      tag = Tag.create!(name: "rounds")

      post "/api/v1/tasks", params: {
        title: "Daily round",
        due_date: "2026-06-29",
        tag_ids: [ tag.id ],
        recurrence: { type: "daily", interval: 1, end_date: "2026-07-03" }
      }, as: :json
      template_id = response.parsed_body.dig("data", "id").split("_")[1]

      delete "/api/v1/tasks/tpl_#{template_id}_2026-07-01/tags/#{tag.id}"

      expect(response).to have_http_status(:ok)

      original = TaskTemplate.find(template_id)
      successor = original.successor_templates.sole
      expect(original.tags).to eq([ tag ])
      expect(successor.tags).to eq([])
      expect(response.parsed_body.dig("data", "id")).to eq("tpl_#{successor.id}_2026-07-01")
    end
  end
end
