module DryCases
  module StepAdapters
    class BaseAdapter
      def initialize(operation:, caller_class:, **, &block)
        @block = block
        @operation = operation
        @caller_class = caller_class
      end

      private

        attr_reader :block, :operation, :caller_class

        def success(input)
          Mixin.success(input)
        end

        def failure(input, key)
          Mixin.failure(input, key: key)
        end

        def call_operation(*inputs, **context)
          operation.call(*inputs, **context)
        end
    end
  end
end
