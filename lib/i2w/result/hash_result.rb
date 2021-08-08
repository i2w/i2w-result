# frozen_string_literal: true

require_relative 'methods'

module I2w
  module Result
    # A Result object that stores a bunch on results.  If any is a failure, the whole is a failure
    # Can be used inside a catch block to exit on the first setting of a failure result,
    # enable this functionality do this by passing a throw_token
    class HashResult
      def self.call(hash_arg = {})
        return new(initial_hash: hash_arg) unless block_given?

        catch do |token|
          result = new(throw_token: token, initial_hash: hash_arg)
          yield result
          result
        end
      end

      include Methods

      def initialize(throw_token: nil, initial_hash: {})
        @throw_token = throw_token
        @hash = {}
        initial_hash.each { set(_1, _2) }
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
        throw @throw_token, self if result.failure? && @throw_token
      end

      # is the result at the key a failure? or if no key given, does the hash contain a failure?
      def failure?(key = NoArg) = key.eql?(NoArg) ? @hash.values.any?(&:failure?) : @hash.fetch(key).failure?

      # is the result at the key success? or if no key given, is the entire hash a success?
      def success?(key = NoArg) = key.eql?(NoArg) ? @hash.values.all?(&:success?) : @hash.fetch(key).success?

      # return the hash of unwrapped failures only
      def failures = @hash.transform_values { _1.failure if _1.failure? }.compact

      # return the hash of unwrapped successes only
      def successes = @hash.transform_values { _1.value if _1.success? }.compact

      # return the hash of successful values, raises ValueCalledOnFailure if any failures
      def value = @hash.transform_values { _1.value }

      alias to_h value
      alias to_hash value

      # failure returns all successful values and failures, but only if there is a failure
      def failure = failure? ? @hash.transform_values { _1.success? ? _1.value : _1.failure } : nil

      # returns the errors for the first failure
      def errors = failure? ? @hash.values.detect(&:failure?).errors : {}
    end
  end
end