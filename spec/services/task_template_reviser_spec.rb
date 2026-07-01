# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskTemplateReviser do
  it "creates successor template for prospective recurring revision" do
    template = TaskTemplate.create!(title: "Daily round", recurrence_type: :daily, start_date: "2026-06-01", interval: 1)
    tag = Tag.create!(name: "rounds")
    template.tags << tag

    successor = described_class.call(
      template:,
      effective_date: Date.new(2026, 7, 1),
      attributes: { title: "Updated round", interval: 2 }
    )

    expect(template.reload.end_date).to eq(Date.new(2026, 6, 30))
    expect(successor.previous_template).to eq(template)
    expect(successor.start_date).to eq(Date.new(2026, 7, 1))
    expect(successor.title).to eq("Updated round")
    expect(successor.interval).to eq(2)
    expect(successor.tags).to eq([ tag ])
  end
end
