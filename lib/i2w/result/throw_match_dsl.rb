# frozen_string_literal: true

module I2w
  module Result
    # initialized with throw token and a result, throws the first evaluated match block when one is found
    class ThrowMatchDSL
      def initialize(found_match, result)
        @found_match = found_match
        @result = result
      end

      # if the result is a success yield with the result value, and throw that
      def success
        return unless @result.success?

        throw @found_match, yield(@result.value)
      end

      # if the result is a failure, and optionally is one of the passed failures,
      # yield with the result failure and errors, and throw that
      def failure(*failures)
        return unless @result.failure?
        return if failures.any? && !failures.include?(@result.failure)

        throw @found_match, yield(@result.failure, @result.errors)
      end
    end
  end
end
