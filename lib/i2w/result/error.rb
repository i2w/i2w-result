# frozen_string_literal: true

require 'forwardable'

module I2w
  module Result
    class Error < RuntimeError
    end

    class NoMatchError < Error
      def initialize(result) = super("match not found for #{result}")
    end

    class FailureError < Error
      attr_reader :cause

      def initialize(failure, cause: nil)
        super failure.to_s
        set_backtrace failure.backtrace
        @cause = cause
      end
    end

    class FailureAddedError < FailureError; end

    class ValueCalledOnFailureError < FailureError; end
  end
end