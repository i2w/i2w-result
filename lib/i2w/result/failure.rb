# frozen_string_literal: true

module I2w
  module Result
    # represents a failure with failure object, and optional errors hash
    class Failure
      attr_reader :failure, :errors

      def initialize(failure, errors = nil)
        @failure = failure
        @errors = errors || (failure.respond_to?(:errors) && failure.errors) || {}
        freeze
      end

      def success? = false

      def failure? = true

      def value = raise(FailureTreatedAsSuccessError, "#value called on Failure #{self}")

      def value_or(arg = nil) = block_given? ? yield(self) : arg

      def deconstruct = [:failure, @failure, @errors.to_hash]

      def and_then = self

      def and_tap = self

      def to_result = self
    end
  end
end
