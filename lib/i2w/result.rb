# frozen_string_literal: true

require_relative 'result/version'
require_relative 'result/success'
require_relative 'result/failure'
require_relative 'result/match'
require_relative 'result/do'

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
    # To use this notation in a method body, include Result::DoWrapper
    def do(&block) = Do.call(&block)
  end
end
