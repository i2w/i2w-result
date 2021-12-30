# frozen_string_literal: true

require 'forwardable'

module I2w
  module Result
    class Error < RuntimeError
    end

    class MatchNotFoundError < Error
      attr_reader :result

      def initialize(result)
        @result = result
        super "match not found for #{result}"
      end
    end

    class FailureError < Error
      attr_reader :result

      def initialize(result, message = result.to_s)
        super message
        @result = result
        set_backtrace result.backtrace
      end
    end

    class ValueCalledOnFailureError < FailureError
      def initialize(result)
        super result, "#value called on #{result}"
      end
    end
  end
end