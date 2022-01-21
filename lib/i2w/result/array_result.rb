# frozen_string_literal: true

require_relative 'methods'
require_relative 'failure_method'
require_relative 'stop_on_failure'

module I2w
  module Result
    class ArrayResult
      extend FailureMethod

      include Methods
      include StopOnFailure

      def initialize(*ary)
        @array = []
        concat(ary)
      end

      def <<(element)
        @array << element_to_result(element)
        self
      end

      def push(*elements)
        @array.push(*elements.map { element_to_result _1 })
        self
      end

      def unshift(*elements)
        @array.unshift(*elements.map { element_to_result _1 })
        self
      end

      def concat(*arrays)
        @array.concat(*arrays.map { |array| array.map { element_to_result _1 } })
        self
      end

      # true if any of our elements is a #failure?
      def failure? = @array.any?(&:failure?)

      # true if all our elements are #success?
      def success? = !failure?

      # return an array of the failure results
      def failure_results = @array.select(&:failure?)

      # return a array of the success results
      def success_results = @array.select(&:success?)

      # return array of unwrapped failures only
      def failures = failure_results.map(&:failure)

      # return array of unwrapped successes only
      def successes = success_results.map(&:value)

      # return the array of successful values, raises ValueCalledOnFailure if any failures
      def value
        return @array.map(&:value) if success?

        raise ValueCalledOnFailureError.new(self), cause: first_failure.to_exception
      end

      alias to_a value
      alias to_ary value

      # failure returns all successful values and failures as an array
      failure_method def failure = @array.transform_values { _1.success? ? _1.value : _1.failure }

      # returns the first failure result
      failure_method def first_failure = @first_failure

      # returns the errors for the first failure
      failure_method def errors = first_failure.errors

      # returns the backtrace for when the first failure was added
      failure_method def backtrace = @backtrace

      # return true if argument threequals (using case equality) the failure, or if it equals the key of the failure
      failure_method def match_failure?(arg) = first_failure.match_failure?(arg)

      # to_exception returns an exception with first_failure as its cause
      failure_method def to_exception
        message = "Failure added to #{self.class}"
        raise FailureError.new(self, message), cause: first_failure.to_exception
      rescue FailureError => e
        e
      end

      private

      def element_to_result(element)
        result = Result.to_result(element)
      ensure
        handle_failure(result) if result.failure?
      end

      def handle_failure(result)
        @first_failure ||= result
        @backtrace ||= caller(2)
        super
      end
    end
  end
end