# frozen_string_literal: true

require_relative 'result/version'
require_relative 'result/success'
require_relative 'result/failure'
require_relative 'result/match'
require_relative 'result/do'
require_relative 'result/hash_result'

module I2w
  # Result monad methods
  module Result
    extend self

    class Error < RuntimeError; end

    class FailureTreatedAsSuccessError < Error; end

    class NoMatchError < Error; end

    def success(...) = Success.new(...)

    def failure(...) = Failure.new(...)

    def wrap
      Success.new(yield)
    rescue StandardError => e
      Failure.new e, { message: e.message }
    end

    # returns result if it can be coerced to result, otherwise wrap in Success monad
    def to_result(obj) = obj.respond_to?(:to_result) ? obj.to_result : success(obj)
    alias [] to_result

    # yield the block using a simple #success #failure(*failures) DSL
    # return the result of the first matching block or raise NoMatchError
    def match(result, &block) = Match.call(result, &block)

    # yield the block using a simple #value! DSL which returns the value of the argument
    # or returns from the block at that point with the failure monad.
    # the return value of the block is returned as a Result.
    #
    # (this is our version of 'do' notation)
    #
    # To use this notation in a #call method body, prepend Result::Do
    def do(&block) = Do.call(&block)

    # yield the block to Result::HashResult, which returns a Result::HashResult (a result monad with multiple values)
    # By default, the first failure added to the hash will cause the block to return early (like 'do' notation)
    # If no block is given, return an empty Result::HashResult (which can have multiple failures added to it)
    def hash_result(...) = HashResult.call(...)
  end
end
