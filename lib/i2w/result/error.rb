# frozen_string_literal: true

require 'forwardable'

module I2w
  module Result
    class Error < RuntimeError
    end

    class NoMatchError < Error
      def initialize(result) = super("match not found for #{result}")
    end

    class FailureTreatedAsSuccessError < Error
      def initialize(result) = super("#value called on #{result}")
    end
  end
end