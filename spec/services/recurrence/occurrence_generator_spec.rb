# frozen_string_literal: true

require "rails_helper"

RSpec.describe Recurrence::OccurrenceGenerator do
  it "generates daily occurrences by interval" do
    template = TaskTemplate.create!(title: "Daily", recurrence_type: :daily, start_date: "2026-07-01", interval: 2)
    window = Recurrence::OccurrenceWindow.call(from: Date.new(2026, 7, 1), to: Date.new(2026, 7, 7))

    expect(dates_for(template, window)).to eq(%w[2026-07-01 2026-07-03 2026-07-05 2026-07-07])
  end

  it "generates monthly occurrences and skips invalid month days" do
    template = TaskTemplate.create!(title: "Monthly", recurrence_type: :monthly, start_date: "2026-01-01", day_of_month: 31)
    window = Recurrence::OccurrenceWindow.call(from: Date.new(2026, 2, 1), to: Date.new(2026, 3, 31))

    expect(dates_for(template, window)).to eq([ "2026-03-31" ])
  end

  it "generates specific date and day parity occurrences" do
    specific = TaskTemplate.create!(
      title: "Specific",
      recurrence_type: :specific_dates,
      start_date: "2026-07-01",
      specific_dates: [ Date.new(2026, 7, 4), Date.new(2026, 7, 10) ]
    )
    parity = TaskTemplate.create!(title: "Odd", recurrence_type: :day_parity, start_date: "2026-07-01", day_parity: :odd)
    window = Recurrence::OccurrenceWindow.call(from: Date.new(2026, 7, 1), to: Date.new(2026, 7, 5))

    expect(dates_for(specific, window)).to eq([ "2026-07-04" ])
    expect(dates_for(parity, window)).to eq(%w[2026-07-01 2026-07-03 2026-07-05])
  end

  def dates_for(template, window)
    described_class.call(template:, window:).map { |instance| instance.occurrence_date.iso8601 }
  end
end
