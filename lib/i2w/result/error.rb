# frozen_string_literal: true

require 'forwardable'

module I2w
  module Result
    class Error < RuntimeError
    end

    class FailureError < Error
      def initialize(failure)
        super failure.to_s
        set_backtrace failure.backtrace
      end
    end

    class NoMatchError < Error
      def initialize(result) = super("match not found for #{result}")
    end

    class FailureTreatedAsSuccessError < Error
      attr_reader :cause

      def initialize(result)
        @cause = result.failure.is_a?(Exception) ? result.failure : FailureError.new(result)
        super "#value called on #{result}"
      end
    end
  end
end