# frozen_string_literal: true

module Callable
  extend ActiveSupport::Concern

  class_methods do
    def call(*args, **keyword_args, &block)
      new(*args, **keyword_args).call(&block)
    end
  end
end
