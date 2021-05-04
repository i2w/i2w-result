# frozen_string_literal: true

module I2w
  module Result
    # represents a failure with failure object/code/symbol, and optional errors
    class Failure
      attr_reader :failure, :errors

      def initialize(failure, errors = nil)
        @failure = failure
        @errors = errors || {}
        freeze
      end

      def success?
        false
      end

      def failure?
        true
      end

      def value
        raise FailureTreatedAsSuccessError, "#value called on Failure #{self}"
      end

      def value_or(arg = nil)
        block_given? ? yield : arg
      end

      def deconstruct
        [:failure, @failure, @errors.to_hash]
      end

      def and_then
        self
      end

      def and_tap
        self
      end

      def to_result
        self
      end
    end
  end
end
