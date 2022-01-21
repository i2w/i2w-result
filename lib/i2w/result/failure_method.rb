# frozen_string_literal: true

module I2w
  module Result
    # extension for decorating methods that are only available when self is a #failure?
    # if one of these methods are called when self if #success?, NoMethodError is raised
    module FailureMethod
      protected

      def failure_method(*method_names)
        method_names.each do |method_name|
          alias_method "_failure_method_#{method_name}", method_name
          private "_failure_method_#{method_name}"
          remove_method method_name

          module_eval <<~end_ruby, __FILE__, __LINE__
            def #{method_name}(...)
              raise NoMethodError, "undefined method `#{method_name}' for #{self.class}:success" if success?

              _failure_method_#{method_name}(...)
            end
          end_ruby
        end
      end
    end
  end
end
