# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 tag forms" do
  it "tag contract validates name and tag ids" do
    tag = Tag.create!(name: "report")

    name_result = Api::V1::TagContract::Name.new.call(name: "ops")
    ids_result = Api::V1::TagContract::TaskTags.new.call(tag_ids: [ tag.id ])

    expect(name_result).to be_success
    expect(ids_result).to be_success
  end

  it "tag form creates updates and refuses protected destroy" do
    create_form = Api::V1::TagForm.call(action: :create, name: "inventory")

    expect(create_form).to be_valid

    update_form = Api::V1::TagForm.call(action: :update, id: create_form.result.id, name: "stock")

    expect(update_form).to be_valid
    expect(update_form.result.name).to eq("stock")

    protected_tag = Tag.create!(name: "операции", protected: true)
    destroy_form = Api::V1::TagForm.call(action: :destroy, id: protected_tag.id)

    expect(destroy_form).not_to be_valid
    expect(destroy_form.error_status).to eq(:forbidden)
  end
end
