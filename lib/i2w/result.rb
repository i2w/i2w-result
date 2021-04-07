# frozen_string_literal: true

require_relative 'result/version'
require_relative 'result/success'
require_relative 'result/failure'
require_relative 'result/throw_match_dsl'

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

    # yield the block using a simple #success #failure(*failures) DSL
    # return the result of the first matching block or raise NoMatchError
    def match(result)
      catch do |found_match|
        yield ThrowMatchDSL.new(found_match, result)
        raise NoMatchError
      end
    end
  end
end
