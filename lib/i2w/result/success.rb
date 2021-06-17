# frozen_string_literal: true

module I2w
  module Result
    # represents a success with a value
    class Success
      attr_reader :value

      def initialize(value)
        @value = value
        freeze
      end

      def success? = true

      def failure? = false

      def value_or(...) = value

      def failure = nil

      def errors = {}

      def deconstruct = [:success, value]

      # return the result of yielding our value (as a Result)
      def and_then = Result.to_result(yield(value))

      # return self, but yield the block with our success value
      def and_tap = tap { yield(value) }

      def to_result = self
    end
  end
end
