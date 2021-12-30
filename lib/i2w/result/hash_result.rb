# frozen_string_literal: true

require_relative 'methods'

module I2w
  module Result
    # A Result object that stores a bunch on results.  If any is a failure, the whole is a failure
    # Can be used to exit (via throw/cath) on the first setting of a failure result, see #stop_on_failure.
    # This mimics the 'do' notation found in other monadic patterns.
    class HashResult
      include Methods

      class << self
        def call(hash_arg = {}, &block)
          return new(hash_arg) unless block

          new(hash_arg).stop_on_failure(&block)
        end
      end

      def initialize(initial_hash = {})
        @hash = {}
        initial_hash.each { set(_1, _2) }
      end

      def stop_on_failure
        catch do |token|
          prev_throw_token, @throw_token = @throw_token, token
          @throw_token = token
          yield self
        ensure
          @throw_token = prev_throw_token
        end
        self
      end

      # return the successful value of the result at the key, raises ValueCalledOnFailure if it is a failure
      def [](key) = @hash[key].value

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
        if result.failure?
          @failure_key ||= key
          @backtrace ||= caller
          throw @throw_token if @throw_token
        end
      end

      # is the result at the key a failure? or if no key given, does the hash contain a failure?
      def failure?(key = NoArg)
        key.eql?(NoArg) ? @hash.values.any?(&:failure?) : @hash.fetch(key).failure?
      end

      # is the result at the key success? or if no key given, is the entire hash a success?
      def success?(key = NoArg)
        key.eql?(NoArg) ? @hash.values.all?(&:success?) : @hash.fetch(key).success?
      end

      # return the hash of unwrapped failures only
      def failures = failure_results.transform_values(&:failure)

      # return the hash of unwrapped successes only
      def successes = success_results.transform_values(&:value)

      # return a hash of the failure results
      def failure_results = @hash.select { _2.failure? }

      # return a hash of the success results
      def success_results = @hash.select { _2.success? }

      # return the hash of successful values, raises ValueCalledOnFailure if any failures
      def value
        return @hash.transform_values { _1.value } if success?

        raise ValueCalledOnFailureError.new(self), cause: first_failure_to_exception
      end

      alias to_h value
      alias to_hash value

      def to_exception
        raise NoMethodError, "undefined method `to_exception' for #{self.class}:success" if success?

        raise FailureError.new(self, message: "Failure added to #{self.class} at :#{first_failure_key}"),
              cause: first_failure_to_exception
      rescue FailureError => exception
        exception
      end

      # failure returns all successful values and failures as a hash
      def failure
        raise NoMethodError, "undefined method `failure' for #{self.class}:success" if success?

        @hash.transform_values { _1.success? ? _1.value : _1.failure }
      end

      # returns the first failure result
      def first_failure
        raise NoMethodError, "undefined method `first_failure' for #{self.class}:success" if success?

        @hash[@failure_key]
      end

      # returns the errors for the first failure
      def errors
        raise NoMethodError, "undefined method `errors' for #{self.class}:success" if success?

        @hash[@failure_key].errors
      end

      # returns the backtrace for when the first failure was added to the hash
      def backtrace
        raise NoMethodError, "undefined method `backtrace' for #{self.class}:success" if success?

        @backtrace
      end

      # returns the key of the first failure
      def first_failure_key
        raise NoMethodError, "undefined method `first_failure_key' for #{self.class}:success" if success?

        @failure_key
      end

      # return true if argument threequals (using case equality) the failure, or if it equals the key of the failure
      def match_failure?(arg)
        raise NoMethodError, "undefined method `match_failure?' for #{self.class}:success" if success?

        (arg === @hash[@failure_key]) || (arg == @failure_key)
      end

      private

      def first_failure_to_exception
        return first_failure if first_failure.is_a?(Exception)
        return first_failure.to_exception if first_failure.respond_to?(:to_exception)
      end
    end
  end
end