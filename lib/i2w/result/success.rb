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

      def success?
        true
      end

      def failure?
        false
      end

      def value_or(...)
        @value
      end

      def failure; end

      def errors
        {}
      end

      def deconstruct
        [:success, @value]
      end

      def and_then
        Result.to_result yield(@value)
      end

      def to_result
        self
      end
    end
  end
end
