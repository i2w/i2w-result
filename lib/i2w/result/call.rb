module I2w
  module Result
    # prepend to decorate the #call method with a result object (which is an OpenResult)
    # the first failure added to the result causes the method to return with the result so far
    # the result object is always returned from #call
    module Call
      def initialize(...)
        @result = OpenResult.new
        super
      end

      def call(...) = result.stop_on_first_failure { super(...) }

      private

      def success(...) = Result.success(...)

      def failure(...) = Result.failure(...)

      attr_reader :result
    end
  end
end