# frozen_string_literal: true

require 'forwardable'

module I2w
  module Result
    class Error < RuntimeError
      attr_reader :result

      def initialize(result, message)
        @result = result
        super message
      end
    end

    class NoMatchError < Error
      def initialize(result) = super(result, "match not found for #{result}")
    end

    class FailureTreatedAsSuccessError < Error
      def initialize(result) = super(result, "#value called on failure #{result.failure}")
    end
  end
end