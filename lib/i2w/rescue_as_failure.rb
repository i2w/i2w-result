# frozen_string_literal: true

module I2w
  # handle raised Exceptions, returning Result.failure errors
  # unhandled exceptions will be raised
  # if no exceptions raised the result is returned as success
  #
  # use #initialize, or #add to add exceptions handlers,
  # a handler is an exception class, or class name, and a block that returns an object suitable for Result.failure
  # 2nd argument (the errors argument) - usually a string (error message) or hash (errors by attribute)
  #
  # #call to yield code which gets exceptions handled
  class RescueAsFailure
    def initialize(exceptions = {})
      @exceptions = {}
      exceptions.each { add _1, _2 }
    end

    def add(exception_class, handler = nil, &block)
      exceptions[exception_class.to_s] = handler || block
    end

    def call
      Result.success yield
    rescue => exception
      if error = error_for_exception(exception)
        Result.failure(exception, error)
      else
        raise exception
      end
    end

    def initialize_dup(source)
      @exceptions = source.exceptions.dup
    end

    def freeze
      @exceptions.freeze
      super
    end

    protected

    attr_reader :exceptions

    private

    def error_for_exception(exception, exception_class = exception.class)
      return if exception_class == Exception # stop at Exception superclass

      if handler = exceptions[exception_class.to_s]
        error = handler.arity == 0 ? handler.call : handler.call(exception)
      end

      error || error_for_exception(exception, exception_class.superclass)
    end

    class << self
      attr_reader :all
    end

    @all = new(StandardError => :message.to_proc).freeze
  end
end