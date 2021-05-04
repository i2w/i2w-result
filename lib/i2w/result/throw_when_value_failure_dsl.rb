# frozen_string_literal: true

module I2w
  module Result
    # initialized with throw token, throws the first #value call has a failure as its argument
    class ThrowWhenValueFailureDSL
      def initialize(got_failure)
        @got_failure = got_failure
      end

      def value(result)
        throw @got_failure, result if result.failure?

        result.value
      end
    end
  end
end
