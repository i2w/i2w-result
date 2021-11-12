# frozen_string_literal: true

module I2w
  module Result
    module Methods
      def failure? = !success?

      # return the value if succes, or failure argument, or block called with failure
      def value_or(arg = nil, &block) = success? ? value : (block&.call(self) || arg)

      def deconstruct = success? ? [:success, value] : [:failure, failure, errors.details]

      # if success, return the result of the block called with value, if failure return self
      def and_then = success? ? Result.to_result(yield(value)) : self

      # if failure, return the result of the block called with failure and errors
      def or_else = success? ? self : Result.to_result(yield(failure, errors))

      # if success, call the block with the value, always return self
      def and_tap = success? ? tap { yield(value) } : self

      def to_result = self
    end
  end
end