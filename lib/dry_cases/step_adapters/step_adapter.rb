module DryCases
  module StepAdapters
    class StepAdapter < BaseAdapter
      prepend ErrorHandler

      def call(*inputs, **context)
        call_operation(*inputs, **context)
      end
    end
  end
end
