# frozen_string_literal: true

require 'forwardable'

module I2w
  module Result
    class Error < RuntimeError; end

    class NoMatchError < Error
      attr_reader :result

      def initialize(result)
        super "match not found for #{result}"
        @result = result
      end
    end

    class FailureTreatedAsSuccessError < Error
      extend Forwardable

      def_delegators :@result, :failure, :errors

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