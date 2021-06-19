module I2w
  module Result
    # prepend this to have the #call method wrapped in Result 'do' syntax
    module Do
      # yield the block with a new Do::DSL object, which responds to #value!, see I2w::Result.do
      def self.call = catch { |tok| Result[yield DSL.new(tok)] }

      # evaluate super, but catching any failure results passed to #value!
      def call(...)
        catch do |tok|
          @_do_dsl = DSL.new(tok)
          Result[super]
        ensure
          @_do_dsl = nil
        end
      end

      private

      def value!(...)
        raise '#value! called without being wrapped. Is I2w::Result::Do prepended?' unless @_do_dsl

        @_do_dsl.value!(...)
      end

      class DSL
        def initialize(tok) = @failure = tok

        def value!(result) = result.failure? ? throw(@failure, result) : result.value
      end
    end
  end
end
