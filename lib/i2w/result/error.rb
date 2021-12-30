# frozen_string_literal: true

require 'forwardable'

module I2w
  module Result
    class Error < RuntimeError
    end

    class NoMatchError < Error
      def initialize(result)
        super "match not found for #{result}"
      end
    end

    class FailureError < Error
      attr_reader :failure_class, :failure_errors

      def initialize(result, message: result.to_s, backtrace: result.backtrace)
        super message
        @failure_class = result.failure.class
        set_backtrace backtrace
      end
    end

    class ValueCalledOnFailureError < FailureError
      def initialize(result)
        super result, message: "#value called on #{result}"
      end
    end
  end
end