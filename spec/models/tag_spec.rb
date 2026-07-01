# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tag, type: :model do
  it "seeds required protected tags" do
    load Rails.root.join("db/seeds.rb")

    %w[отчетность операции звонок].each do |name|
      tag = described_class.find_by!(name:)

      expect(tag).to be_protected
    end
  end

  it "protected tags reject update and destroy" do
    tag = described_class.create!(name: "операции", protected: true)

    expect(tag.update(name: "new name")).to be(false)
    expect(tag.errors[:base]).to include("protected tags cannot be changed")

    expect(tag.destroy).to be(false)
    expect(tag.errors[:base]).to include("protected tags cannot be deleted")
  end
end
