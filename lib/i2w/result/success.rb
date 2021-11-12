# frozen_string_literal: true

require_relative 'methods'

module I2w
  module Result
    class Success
      include Methods

      attr_reader :value

      def initialize(value)
        @value = value
        freeze
      end

      def success? = true
    end
  end
end