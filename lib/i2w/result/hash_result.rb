# frozen_string_literal: true

require_relative 'methods'

module I2w
  module Result
    # A Result object that stores a bunch on results.  If any is a failure, the whole is a failure
    # Can be used to exit (via throw/cath) on the first setting of a failure result, see #stop_on_failure.
    # This mimics the 'do' notation found in other monadic patterns.
    class HashResult
      include Methods

      NoArg = Object.new.freeze

      class << self
        def call(hash_arg = {}, &block)
          return new(hash_arg) unless block

          new(hash_arg).stop_on_failure(&block)
        end

        private

        # decorator for instance methods that raises a NoMethodError unless the result is a failure
        def failure_method(method_name)
          orig = instance_method(method_name)
          remove_method(method_name)
          define_method(method_name) do |*args|
            raise NoMethodError, "undefined method `#{method_name}' for success:#{self.class}" if success?
            orig.bind(self).call(*args)
          end
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
          @failure_added_backtrace ||= caller_locations if Result.config.save_backtrace_on_failure
          throw @throw_token if @throw_token
        end
      end

      # is the result at the key a failure? or if no key given, does the hash contain a failure?
      def failure?(key = NoArg) = key.eql?(NoArg) ? @hash.values.any?(&:failure?) : @hash.fetch(key).failure?

      # is the result at the key success? or if no key given, is the entire hash a success?
      def success?(key = NoArg) = key.eql?(NoArg) ? @hash.values.all?(&:success?) : @hash.fetch(key).success?

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
        raise(FailureTreatedAsSuccessError, self) unless success?

        @hash.transform_values { _1.value }
      end

      alias to_h value
      alias to_hash value

      # failure returns all successful values and failures as a hash
      failure_method def failure = @hash.transform_values { _1.success? ? _1.value : _1.failure }

      # returns the first failure result
      failure_method def first_failure = @hash[@failure_key]

      # returns the errors for the first failure
      failure_method def errors = @hash[@failure_key].errors

      # returns the backtrace for the first failure
      failure_method def backtrace = @hash[@failure_key].backtrace

      # returns the backtrace for when the first failure waas added to this result
      failure_method def failure_added_backtrace = @failure_added_backtrace

      # returns the key of the first failure
      failure_method def first_failure_key = @failure_key

      # return true if argument threequals (using case equality) the failure, or if it equals the key of the failure
      failure_method def match_failure?(arg) = (arg === @hash[@failure_key]) || (arg == @failure_key)
    end
  end
end