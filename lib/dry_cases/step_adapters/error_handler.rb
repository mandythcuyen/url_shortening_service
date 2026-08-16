module DryCases
  module StepAdapters
    module ErrorHandler
      def initialize(error: nil, **inputs, &)
        super(**inputs, &)
        @error = error
      end

      def call(*inputs, **context)
        result = super.to_result

        return result if result.success?

        failure(handle_error(result.failure), operation.name)
      end

      private

        attr_reader :error

        def add_error(input)
          input.errors.add(:base, error) unless error.nil?

          input
        end

        def errors(object)
          error_object = error.nil? ? {} : { base: [ error ] }
          error_object[:codes] = []

          error_object.merge!(object.errors.messages) if object.respond_to?(:errors)
          error_object.merge!(object) if object.is_a?(Hash)

          error_object
        end

        def handle_error(object)
          operation.receiver.class.simple_errors_enabled? ? errors(object) : add_error(object)
        end
    end
  end
end
