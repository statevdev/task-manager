# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Tasks", type: :request do
  it "creates, shows, updates, lists, and deletes a one-time task" do
    post "/api/v1/tasks", params: {
      title: "Call patient",
      description: "Check condition after discharge",
      due_date: "2026-07-01"
    }, as: :json

    expect(response).to have_http_status(:created)
    task = response.parsed_body.fetch("data")
    expect(task.fetch("id")).to match(/\Atpl_\d+_2026-07-01\z/)
    expect(task.fetch("title")).to eq("Call patient")
    expect(task.fetch("status")).to eq("pending")
    expect(task.fetch("recurrence")).to be_nil

    get "/api/v1/tasks/#{task.fetch("id")}"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "id")).to eq(task.fetch("id"))

    patch "/api/v1/tasks/#{task.fetch("id")}", params: {
      title: "Call patient again",
      status: "completed"
    }, as: :json

    expect(response).to have_http_status(:ok)
    updated = response.parsed_body.fetch("data")
    expect(updated.fetch("title")).to eq("Call patient again")
    expect(updated.fetch("status")).to eq("completed")

    get "/api/v1/tasks", params: {
      from: "2026-07-01",
      to: "2026-07-07",
      status: [ "completed" ]
    }

    expect(response).to have_http_status(:ok)
    ids = response.parsed_body.fetch("data").map { |item| item.fetch("id") }
    expect(ids).to include(task.fetch("id"))

    delete "/api/v1/tasks/#{task.fetch("id")}"

    expect(response).to have_http_status(:no_content)

    get "/api/v1/tasks/#{task.fetch("id")}"

    expect(response).to have_http_status(:not_found)

    get "/api/v1/tasks", params: { from: "2026-07-01", to: "2026-07-07" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").map { |item| item.fetch("id") }).not_to include(task.fetch("id"))
  end

  it "rejects invalid list window" do
    get "/api/v1/tasks", params: { from: "2026-07-08", to: "2026-07-01" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("errors")).to be_present
  end
end
