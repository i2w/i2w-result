# frozen_string_literal: true

module I2w
  module Result
    class Failure
      class ErrorsWrapper
        class << self
          include ActiveModel::Translation
          include ActiveModel::Naming
        end

        def initialize(failure)
          @failure = failure
        end

        def model_name
          return @failure.model_name       if @failure.respond_to?(:model_name)
          return @failure.class.model_name if @failure.class.respond_to?(:model_name)

          self.class.model_name
        end

        def read_attribute_for_validation(attr)
          return @failure.read_attribute_for_validation(attr) if @failure.respond_to?(:read_attribute_for_validation)
          return @failure.to_h[attr] if @failure.respond_to?(:to_h)
        end
      end
    end
  end
end