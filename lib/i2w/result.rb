# frozen_string_literal: true

require_relative 'result/version'
require_relative 'result/success'
require_relative 'result/failure'
require_relative 'result/throw_when_state_matched_dsl'
require_relative 'result/throw_when_value_failure_dsl'

module I2w
  # Result monad methods
  module Result
    extend self

    class Error < RuntimeError; end

    class FailureTreatedAsSuccessError < Error; end

    class NoMatchError < Error; end

    def success(...)
      Success.new(...)
    end

    def failure(...)
      Failure.new(...)
    end

    # returns result if it can be coerced to result, otherwise wrap in Success monad
    def to_result(obj)
      obj.respond_to?(:to_result) ? obj.to_result : success(obj)
    end
    alias [] to_result

    # yield the block using a simple #success #failure(*failures) DSL
    # return the result of the first matching block or raise NoMatchError
    def match(result, &block)
      catch do |found_match|
        ThrowWhenStateMatchedDSL.new(found_match, result).instance_eval(&block)
        raise NoMatchError
      end
    end

    # yield the block using a simple #value DSL which returns the value of the argument
    # or returns from the block at that point with the failure monad.
    # the return value of the block is returned as a Result.
    # 
    # (this is our version of 'do' notation)
    def call(&block)
      catch do |got_failure|
        result = ThrowWhenValueFailureDSL.new(got_failure).instance_eval(&block)
        Result[result]
      end
    end
  end
end
