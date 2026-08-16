module DryCases
  module Mixin
    include Dry::Monads::Result::Mixin

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def step_ops
        @step_ops ||= []
      end

      def use_simple_errors(value = false)
        @enable_simple_errors ||= value
      end

      def simple_errors_enabled?
        @enable_simple_errors
      end

      DryCases::StepAdapters::Configuration.adapters.each do |name, klass|
        define_method(name) do |operation = nil, **params, &block|
          step_ops << {
            block:     block,
            operation: operation,
            klass:     klass,
            params:    params,
          }
        end
      end

      def call(param, **context)
        new.call(param, **context)
      end
    end

    def call(params, failure_handler: proc { }, **context)
      result =
        steps.reduce(success(params)) do |memo, step|
          memo.bind do |value|
            result = step.call(value, **context)
            result
          end
        end
      failure_handler.call(result.failure) if result.failure?
      result
    end

    private

      def steps
        @steps ||=
          self.class.step_ops.map do |step_op|
            step_op[:klass].new(
              caller_class: self,
              operation:    method_resolver(step_op[:operation]),
              **step_op[:params],
              &step_op[:block]
            )
          end
      end

      def method_resolver(operation)
        case operation
        when Symbol
          method(operation)
        else
          operation if operation.respond_to?(:call)
        end
      end

      def failure(input, key: caller_locations(1..1).first.label.to_sym)
        Dry::Monads::Failure.new(input, key)
      end

      def success(input)
        Dry::Monads::Success(input)
      end

      module_function :success, :failure
  end
end
