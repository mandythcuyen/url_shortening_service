module DryCases
  module StepAdapters
    module Configuration
      def self.adapters
        @adapters ||= {}
      end

      def self.register(name, klass)
        adapters[name] = klass
      end

      register :step, StepAdapter
      register :db, DbAdapter
      register :check, CheckAdapter
    end
  end
end
