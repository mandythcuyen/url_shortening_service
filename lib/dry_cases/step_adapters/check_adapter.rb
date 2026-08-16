module DryCases
  module StepAdapters
    class CheckAdapter < BaseAdapter
      prepend ErrorHandler

      def call(input, **context)
        result = call_operation(input, **context)

        if result.is_a?(Dry::Monads::Result)
          result
        elsif result
          success(input)
        else
          failure(input, operation.name)
        end
      end
    end
  end
end
