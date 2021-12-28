# frozen_string_literal: true

require 'active_model/errors'
require 'active_model/naming'
require 'active_model/translation'

require_relative 'methods'

module I2w
  module Result
    class Failure
      extend ActiveModel::Translation
      include Methods

      attr_reader :failure, :errors, :backtrace

      def initialize(failure, errors = nil)
        @backtrace = caller if Result.config.save_backtrace_on_failure
        @failure = failure
        errors ||= failure.errors if failure.respond_to?(:errors)
        @errors = convert_errors(errors)
        freeze
      end

      def value = raise(FailureTreatedAsSuccessError, self)

      def success? = false

      # match the argument against our failure using case equality
      def match_failure?(arg) = arg === failure

      private

      def convert_errors(errors)
        return errors if errors.respond_to?(:full_messages)

        ActiveModel::Errors.new(self).tap do |errors_obj|
          if errors.respond_to?(:to_h)
            errors.to_h.each { |key, errs| Array(errs).each { errors_obj.add(key, _1) } }
          elsif errors.present?
            errors_obj.add(:base, errors.to_s)
          end
        end
      end
    end
  end
end