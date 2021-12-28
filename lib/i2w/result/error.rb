# frozen_string_literal: true

require 'forwardable'

module I2w
  module Result
    class Error < RuntimeError
      attr_reader :cause

      def initialize(result, message)
        @cause = result.failure if result.failure? && result.failure.is_a?(Exception)
        super message
      end
    end

    class NoMatchError < Error
      def initialize(result) = super(result, "match not found for #{result}")
    end

    class FailureTreatedAsSuccessError < Error
      def initialize(result) = super(result, "#value called on #{result}")
    end
  end
end