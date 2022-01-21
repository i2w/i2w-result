module I2w
  module Result
    module StopOnFailure
      def self.included(into)
        into.extend ClassMethods
      end

      module ClassMethods
        def call(*args, **kwargs, &block)
          return new(*args, **kwargs) unless block

          new(*args, **kwargs).stop_on_failure(&block)
        end
      end

      def stop_on_failure
        catch do |token|
          prev_throw_token, @failure_throw_token = @failure_throw_token, token
          @failure_throw_token = token
          yield self
        ensure
          @failure_throw_token = prev_throw_token
        end
        self
      end

      protected

      def handle_failure(result)
        throw @failure_throw_token, result if @failure_throw_token && result.failure?
      end
    end
  end
end