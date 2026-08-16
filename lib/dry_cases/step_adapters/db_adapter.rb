module DryCases
  module StepAdapters
    class DbAdapter < WrapAdapter
      def call(*inputs, **context)
        use_case = nil

        ActiveRecord::Base.transaction do
          klass = Class.new(caller_class.class)
          klass.instance_variable_set(:@enable_simple_errors, caller_class.class.simple_errors_enabled?)
          klass.instance_exec(&block)
          use_case = klass.call(*inputs, **context)

          raise ActiveRecord::Rollback if use_case.failure?
        end

        use_case
      end
    end
  end
end
