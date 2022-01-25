# frozen_string_literal: true

require_relative 'no_arg'
require_relative 'rescue_as_failure'
require_relative 'result/version'
require_relative 'result/error'
require_relative 'result/success'
require_relative 'result/failure'
require_relative 'result/match'
require_relative 'result/hash_result'
require_relative 'result/open_result'
require_relative 'result/array_result'

module I2w
  # Result monad, built for rails
  module Result
    extend self

    # a successful result
    def success(value) = Success.new(value)

    # a failure result
    def failure(failure, errors = nil) = Failure.new(failure, errors)

    # yield the block to Result::HashResult, which returns a Result::HashResult (a result monad with multiple values)
    # By default, the first failure added to the hash will cause the block to return early (like 'do' notation)
    # If no block is given, return an empty Result::HashResult (which can have multiple failures added to it)
    def hash_result(...) = HashResult.call(...)

    # similar to hash_result, but allows get/set via method access
    def open_result(...) = OpenResult.call(...)

    # array result represents an array of results, it is #success? when all elements are #success?
    # Similar in API to #hash_result, by default the first failure added to the array will cause the block to
    # return early, but you can add multiple failures by passing them, or #push-ing them
    def array_result(...) = ArrayResult.call(...)

    # returns result if it can be coerced to result, otherwise wrap in Success monad,
    # if a block is given, yield the result and rescue any errors as failures
    def to_result(obj = nil, &block)
      obj = RescueAsFailure.all.call(&block) if block
      obj.respond_to?(:to_result) ? obj.to_result : success(obj)
    end

    # yield the block using a simple #success #failure(*failures) DSL
    # return the result of the first matching block or raise NoMatchError
    def match(result, &block) = Match.call(result, &block)

    # lift the wrapped result value, or return the argument if it is not a result
    def value(object) = to_result(object).value

    # shortcut to wrap an object in a result
    def self.[](obj) = Result.to_result(obj)
  end
end
