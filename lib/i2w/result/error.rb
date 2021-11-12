# frozen_string_literal: true

require 'forwardable'

module I2w
  module Result
    class Error < RuntimeError; end

    class NoMatchError < Error; end

    class FailureTreatedAsSuccessError < Error
      extend Forwardable

      def_delegators :@result, :failure, :errors, :backtrace, :failure_added_backtrace

      attr_reader :result

      def initialize(result)
        super "#value called on failure #{result.failure}"
        @result = result
      end

      # raises the failure if the failure is an exception, otherwise re-raise self
      def raise_failure! = raise(failure.is_a?(Exception) ? failure : self)
    end
  end
end