# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::TaskCreateContract do
  it "accepts a one-time task payload" do
    result = described_class.new.call(
      title: "Prepare report",
      description: "Monthly report",
      due_date: "2026-07-01"
    )

    expect(result).to be_success
    expect(result.to_h.fetch(:due_date)).to eq(Date.new(2026, 7, 1))
  end

  it "rejects blank title" do
    result = described_class.new.call(title: "", due_date: "2026-07-01")

    expect(result).to be_failure
    expect(result.errors.to_h).to include(:title)
  end
end

RSpec.describe Api::V1::TaskIndexContract do
  it "requires ordered bounded dates" do
    result = described_class.new.call(from: "2026-07-10", to: "2026-07-01")

    expect(result).to be_failure
    expect(result.errors.to_h).to include(:to)
  end
end

RSpec.describe Api::V1::TaskIdContract do
  it "parses expected id shape" do
    result = described_class.new.call(id: "tpl_12_2026-07-01")

    expect(result).to be_success
    expect(result.to_h.fetch(:public_task_id).task_template_id).to eq(12)
  end
end
