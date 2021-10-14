# frozen_string_literal: true

module I2w
  module Result
    module Methods
      def failure? = !success?

      def value_or(arg = nil, &block) = success? ? value : (block&.call(self) || arg)

      def deconstruct = success? ? [:success, value] : [:failure, failure, errors.to_hash]

      def and_then = success? ? Result.to_result(yield(value)) : self

      def and_tap = success? ? tap { yield(value) } : self

      def on_success = success? ? Result.to_result(yield(self)) : self

      def on_failure = success? ? self : Result.to_result(yield(self))

      def to_result = self
    end
  end
end