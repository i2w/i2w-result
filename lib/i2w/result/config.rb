# frozen_string_literal: true

require 'active_support/ordered_options'

module I2w
  module Result
    module Config
      def self.extended(into)
        into.instance_variable_set :@config, ActiveSupport::OrderedOptions.new
      end

      attr_reader :config

      def configure = yield(config)
    end
  end
end