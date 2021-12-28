# frozen_string_literal: true

require_relative 'no_arg'
require_relative 'result/version'
require_relative 'result/error'
require_relative 'result/success'
require_relative 'result/failure'
require_relative 'result/match'
require_relative 'result/hash_result'
require_relative 'result/open_result'

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

    # yield the block, and return success, but if any exceptions occur return a failure wrapping the exception
    def wrap
      success yield
    rescue StandardError => e
      failure e, e.message
    end

    # returns result if it can be coerced to result, otherwise wrap in Success monad
    def to_result(obj) = obj.respond_to?(:to_result) ? obj.to_result : success(obj)

    # yield the block using a simple #success #failure(*failures) DSL
    # return the result of the first matching block or raise NoMatchError
    def match(result, &block) = Match.call(result, &block)

    def self.[](...) = to_result(...)
  end
end
