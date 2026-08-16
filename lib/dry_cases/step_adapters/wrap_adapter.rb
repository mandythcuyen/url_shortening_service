module DryCases
  module StepAdapters
    class WrapAdapter < BaseAdapter
      def call(input, **context)
        klass = Class.new(caller_class.class)
        klass.instance_variable_set(:@enable_simple_errors, caller_class.class.simple_errors_enabled?)
        klass.instance_exec(&block)
        call_operation(input, klass, **context)
      end
    end
  end
end
