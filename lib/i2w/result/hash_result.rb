# frozen_string_literal: true

require_relative 'methods'
require_relative 'failure_method'
require_relative 'stop_on_failure'

module I2w
  module Result
    # A Result object that stores a bunch on results.  If any is a failure, the whole is a failure
    # Can be used to exit (via throw/catch) on the first setting of a failure result, see #stop_on_failure.
    # This mimics the 'do' notation found in other monadic patterns.
    class HashResult
      extend FailureMethod
      include Methods
      include StopOnFailure

      def initialize(initial_hash = {})
        @hash = {}
        initial_hash.each { set(_1, _2) }
      end

      def initialize_copy(source)
        @hash = source.results
      end

      delegate :slice, :except, to: :value

      # return the successful value of the result at the key, raises ValueCalledOnFailure if it is a failure
      # return nil if the key is not present
      def [](key) = @hash[key]&.value

      # set the result, if two keys given, the left is set for success, right for failure
      def []=(*key, value)
        set(key[0], value, failure_key: key[1] || NoArg)
      end

      # using this method, you can set the result at a different failure key, if it is a failure
      def set(key, value, failure_key: NoArg)
        result = Result.to_result(value)
        key = failure_key if result.failure? && failure_key != NoArg
        @hash[key] = result
      ensure
        handle_failure(result, key) if result.failure?
      end

      # is the result at the key a failure? or if no key given, does the hash contain a failure?
      def failure?(key = NoArg)
        key.eql?(NoArg) ? @hash.values.any?(&:failure?) : @hash.fetch(key).failure?
      end

      # is the result at the key success? or if no key given, is the entire hash a success?
      def success?(...) = !failure?(...)

      # return the hash of unwrapped failures only
      def failures = failure_results.transform_values(&:failure)

      # return the hash of unwrapped successes only
      def successes = success_results.transform_values(&:value)

      # return a normal hash of the underlying results
      def results = @hash.dup

      # return a hash of the failure results
      def failure_results = @hash.select { _2.failure? }

      # return a hash of the success results
      def success_results = @hash.select { _2.success? }

      # return the hash of successful values, raises ValueCalledOnFailure if any failures
      def value
        return @hash.transform_values { _1.value } if success?

        raise ValueCalledOnFailureError.new(self), cause: first_failure_result.to_exception
      end

      alias to_h value
      alias to_hash value

      # failure returns all successful values and failures as a hash
      failure_method def failure = @hash.transform_values { _1.success? ? _1.value : _1.failure }

      # returns the first failure result
      failure_method def first_failure_result = @hash[@failure_key]

      # returns the first failure
      failure_method def first_failure = first_failure_result.failure

      # returns the errors for the first failure
      failure_method def errors = first_failure_result.errors

      # returns the backtrace for when the first failure was added to the hash
      failure_method def backtrace = @backtrace

      # returns the key of the first failure
      failure_method def first_failure_key = @failure_key

      # return true if argument threequals (using case equality) the failure, or if it equals the key of the failure
      failure_method def match_failure?(arg) = (arg == first_failure_key || first_failure_result.match_failure?(arg))

      # to_exception returns an exception with first_failure as its cause
      failure_method def to_exception
        message = "Failure :#{first_failure_key} added to #{self.class}"
        raise FailureError.new(self, message), cause: first_failure_result.to_exception
      rescue FailureError => e
        e
      end

      private

      def handle_failure(result, key)
        @failure_key ||= key
        @backtrace ||= caller(2)
        super(result)
      end
    end
  end
end