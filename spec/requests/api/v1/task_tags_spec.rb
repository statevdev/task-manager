# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::TaskTags", type: :request do
  it "attaches and removes tags from a task template" do
    call_tag = Tag.create!(name: "звонок", protected: true)
    report_tag = Tag.create!(name: "отчетность", protected: true)
    task = Api::V1::TaskCreateForm.call(title: "Call patient", due_date: "2026-07-01").result
    public_id = PublicTaskId.format(task_template_id: task.task_template_id, occurrence_date: task.occurrence_date)

    post "/api/v1/tasks/#{public_id}/tags", params: { tag_ids: [ call_tag.id, report_tag.id ] }, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "tags").map { |tag| tag.fetch("name") }.sort).to eq(%w[звонок отчетность].sort)

    delete "/api/v1/tasks/#{public_id}/tags/#{call_tag.id}"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "tags").map { |tag| tag.fetch("name") }).to eq([ "отчетность" ])
  end
end
