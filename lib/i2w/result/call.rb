module I2w
  module Result
    # include this to have the #call method wrapped in Result call (do) syntax, also applies to all descendents
    module Call
      extend ActiveSupport::Concern

      included do
        prepend Methods

        def self.inherited(subclass)
          super
          subclass.prepend Methods
        end
      end

      # create a throwaway object to evaluate the block in
      def self.call(&block)
        Object.new.tap { _1.singleton_class.prepend(Methods).define_method(:call, &block) }.call
      end

      module Methods
        def call(...)
          catch do |got_failure|
            @got_failure = got_failure
            Result[super]
          end
        end

        def value(result)
          throw @got_failure, result if result.failure?

          result.value
        end
      end
    end
  end
end
