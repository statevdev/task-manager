# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::TaskCreateContract do
  it "accepts daily recurrence" do
    result = described_class.new.call(
      title: "Daily round",
      due_date: "2026-07-01",
      recurrence: { type: "daily", interval: 2, end_date: "2026-07-10" }
    )

    expect(result).to be_success
    expect(result.to_h.dig(:recurrence, :type)).to eq("daily")
  end

  it "accepts monthly specific dates and day parity recurrence" do
    monthly = described_class.new.call(title: "Inventory", due_date: "2026-07-01", recurrence: { type: "monthly", day_of_month: 15 })
    specific = described_class.new.call(title: "Report", due_date: "2026-07-01", recurrence: { type: "specific_dates", specific_dates: [ "2026-07-03", "2026-07-09" ] })
    parity = described_class.new.call(title: "Even reports", due_date: "2026-07-01", recurrence: { type: "day_parity", day_parity: "even" })

    expect(monthly).to be_success
    expect(specific).to be_success
    expect(parity).to be_success
  end

  it "rejects recurrence missing required type parameters" do
    daily = described_class.new.call(title: "Daily round", due_date: "2026-07-01", recurrence: { type: "daily" })
    monthly = described_class.new.call(title: "Inventory", due_date: "2026-07-01", recurrence: { type: "monthly" })

    expect(daily).to be_failure
    expect(monthly).to be_failure
  end
end
