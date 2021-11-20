# frozen_string_literal: true

module I2w
  module Result
    # result methods, requires #success? to be defined
    # if success, #value must be defined, otherwise #failure and #errors must be defined
    module Methods
      def failure? = !success?

      # return the value if succes, or failure argument, or block called with self
      def value_or(arg = nil, &block) = success? ? value : (block&.call(self) || arg)

      # if success, return the result of the block called with value, if failure return self
      def and_then = success? ? Result.to_result(yield(value)) : self

      # if failure, return the result of the block called with failure and errors, if success return self
      def or_else = success? ? self : Result.to_result(yield(failure, errors))

      # if success, call the block with the value, always return self
      def and_tap = success? ? tap { yield(value) } : self

      def to_result = self
    end
  end
end