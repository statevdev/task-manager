# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Tags", type: :request do
  it "creates, lists, updates, and deletes unprotected tags" do
    post "/api/v1/tags", params: { name: "lab" }, as: :json

    expect(response).to have_http_status(:created)
    tag = response.parsed_body.fetch("data")
    expect(tag.fetch("name")).to eq("lab")
    expect(tag.fetch("protected")).to be(false)

    get "/api/v1/tags"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").map { |item| item.fetch("id") }).to include(tag.fetch("id"))

    patch "/api/v1/tags/#{tag.fetch("id")}", params: { name: "laboratory" }, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "name")).to eq("laboratory")

    delete "/api/v1/tags/#{tag.fetch("id")}"

    expect(response).to have_http_status(:no_content)
  end

  it "protected tags reject update and delete" do
    tag = Tag.create!(name: "звонок", protected: true)

    patch "/api/v1/tags/#{tag.id}", params: { name: "calls" }, as: :json

    expect(response).to have_http_status(:forbidden)

    delete "/api/v1/tags/#{tag.id}"

    expect(response).to have_http_status(:forbidden)
  end
end
