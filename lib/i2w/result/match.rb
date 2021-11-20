# frozen_string_literal: true

module I2w
  module Result
    class Match
      def self.call(result)
        catch do |tok|
          yield DSL.new(tok, result)
          raise NoMatchError.new(result)
        end
      end

      # initialized with throw token and a result, throws the first evaluated match block when one is found
      class DSL
        def initialize(tok, result)
          @found_match = tok
          @result = result
        end

        # if the result is a success yield with the result value, and throw that
        def success
          return unless @result.success?

          throw @found_match, yield(@result.value)
        end

        # if the result is a failure, and optionally is one of the passed failures,
        # yield with the result(failure, errors, match) and throw that
        def failure(*failures)
          return unless @result.failure?
          return unless match = failures.detect { @result.match_failure? _1 }

          throw @found_match, yield(@result.failure, @result.errors, match)
        end
      end
    end
  end
end
