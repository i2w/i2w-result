# frozen_string_literal: true

require 'active_model/errors'
require 'active_model/naming'
require 'active_model/translation'

require_relative 'result/version'
require_relative 'result/methods'
require_relative 'result/match'
require_relative 'result/hash_result'
require_relative 'result/open_result'

module I2w
  # Result monad
  module Result
    extend self

    def success(value) = Success.new(value)

    def failure(failure, errors = nil) = Failure.new(failure, errors)

    # yield the block to Result::HashResult, which returns a Result::HashResult (a result monad with multiple values)
    # By default, the first failure added to the hash will cause the block to return early (like 'do' notation)
    # If no block is given, return an empty Result::HashResult (which can have multiple failures added to it)
    def hash_result(...) = HashResult.call(...)

    # similar to hash_result, but allows get/set via method access
    def open_result(...) = OpenResult.call(...)

    # yield the block, and return success, but if any exceptions occur return a failure wrapping the exception
    def wrap
      success yield
    rescue StandardError => e
      failure e, exception: e.message
    end

    # returns result if it can be coerced to result, otherwise wrap in Success monad
    def to_result(obj) = obj.respond_to?(:to_result) ? obj.to_result : success(obj)

    # yield the block using a simple #success #failure(*failures) DSL
    # return the result of the first matching block or raise NoMatchError
    def match(result, &block) = Match.call(result, &block)

    def self.[](...) = to_result(...)

    class Error < RuntimeError; end

    class NoMatchError < Error; end

    class FailureTreatedAsSuccessError < Error
      attr_reader :result

      def initialize(result)
        super "#value called on failure #{result.failure}"
        @result = result
      end

      def failure = result.failure

      def errors = result.errors

      def raise! = raise(failure.is_a?(Exception) ? failure : self)
    end

    class Success
      include Methods

      attr_reader :value

      def initialize(value)
        @value = value
        freeze
      end

      def success? = true

      def failure = nil

      def errors = {}
    end

    class Failure
      extend ActiveModel::Translation
      include Methods

      attr_reader :failure, :errors

      def initialize(failure, errors = nil)
        @failure = failure
        errors ||= failure.errors if failure.respond_to?(:errors)
        @errors = convert_errors(errors)
        freeze
      end

      def value = raise(FailureTreatedAsSuccessError, self)

      def success? = false

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
