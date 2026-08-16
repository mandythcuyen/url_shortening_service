# frozen_string_literal: true

module Services
  class BaseService
    attr_reader :result, :message, :debug_info

    def initialize(*args)
      raise NotImplementedError
    end

    def perform
      raise NotImplementedError
    end

    def success?
      !failure?
    end

    def failure?
      @success.blank? && @message.present?
    end

    private

    def success!(result)
      @success = true
      @result = result

      @result
    end

    def fail!(message, debug_info = {})
      @success = false
      @message = message
      @debug_info = debug_info
      backtrace = debug_info.respond_to?(:backtrace) ? debug_info.backtrace : nil

      Rails.logger.error "#{self.class.name} error: #{@message}"
      Rails.logger.error backtrace&.join("\n")

      nil
    end
  end
end
