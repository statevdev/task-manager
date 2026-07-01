# frozen_string_literal: true

require "rails_helper"

RSpec.describe Recurrence::OccurrenceWindow do
  it "builds inclusive bounded window" do
    window = described_class.call(from: Date.new(2026, 7, 1), to: Date.new(2026, 7, 31))

    expect(window.from).to eq(Date.new(2026, 7, 1))
    expect(window.to).to eq(Date.new(2026, 7, 31))
    expect(window.range).to include(Date.new(2026, 7, 15))
  end

  it "rejects inverted and too large windows" do
    expect { described_class.call(from: Date.new(2026, 7, 10), to: Date.new(2026, 7, 1)) }.to raise_error(ArgumentError)
    expect { described_class.call(from: Date.new(2026, 1, 1), to: Date.new(2027, 1, 2)) }.to raise_error(ArgumentError)
  end
end
