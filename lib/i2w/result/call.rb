module I2w
  module Result
    # include this to have the #call method wrapped in Result call (do) syntax, also applies to all descendents
    module Call
      extend ActiveSupport::Concern

      included do
        prepend PrependMethods

        def self.inherited(subclass)
          super
          subclass.prepend PrependMethods
        end
      end

      # create a throwaway object to evaluate the block in
      def self.call(&block)
        Object.new.tap { |obj| obj.singleton_class.prepend(PrependMethods).define_method(:call, &block) }.call
      end

      module PrependMethods
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
