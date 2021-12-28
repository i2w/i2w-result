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
      def initialize(failure)
        super failure.to_s
        set_backtrace failure.backtrace
      end
    end

    class ValueCalledOnFailureError < Error
      def initialize(failure)
        super "#value called on #{failure}"
      end
    end
  end
end