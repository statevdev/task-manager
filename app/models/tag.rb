# frozen_string_literal: true

class Tag < ApplicationRecord
  REQUIRED_PROTECTED_NAMES = %w[отчетность операции звонок].freeze

  has_many :task_template_tags, dependent: :destroy
  has_many :task_templates, through: :task_template_tags

  validates :name, presence: true, uniqueness: true

  before_update :reject_protected_update
  before_destroy :reject_protected_destroy

  private

  def reject_protected_update
    return unless protected?

    errors.add(:base, "protected tags cannot be changed")
    throw :abort
  end

  def reject_protected_destroy
    return unless protected?

    errors.add(:base, "protected tags cannot be deleted")
    throw :abort
  end
end
