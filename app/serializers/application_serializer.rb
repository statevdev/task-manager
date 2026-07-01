# frozen_string_literal: true

class ApplicationSerializer
  include Callable

  class << self
    def views
      @views ||= superclass.respond_to?(:views) ? superclass.views.dup : {}
    end

    def view(name = :default, &block)
      views[name] = block
    end
  end

  def initialize(record, view: :default)
    @record = record
    @view_name = view
  end

  def call
    case record
    when nil then nil
    when Enumerable then record.map { |item| self.class.call(item, view: view_name) }
    else
      instance_eval(&self.class.views.fetch(view_name))
    end
  end

  private

  attr_reader :record, :view_name

  def serialize_date(date)
    date&.iso8601
  end

  def serialize_datetime(datetime)
    datetime&.iso8601(6)
  end
end
