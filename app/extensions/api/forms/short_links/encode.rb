require "uri"
require "ipaddr"

module Api
  module Forms
    module ShortLinks
      class Encode
        include ActiveModel::Model

        attr_reader :url,
                    :session_token,
                    :uri

        validates_presence_of :url, :session_token
        validate :valid_url?, unless: -> { url.blank? }

        def initialize(url:, session_token:)
          @url = url.to_s.strip
          @session_token = session_token
          @uri = URI.parse(@url)
        rescue URI::InvalidURIError
          @uri = nil
        end

        def valid_url?
          valid_length? && valid_format? && valid_scheme? &&
          valid_host? && no_user_info? && not_blocked_host?
        end

        # validate URL length
        def valid_length?
          return true if @url.length <= 2048

          errors.add(:base, :invalid, message: "URL is too long")
          false
        end

        # validate URL format
        def valid_format?
          return true if url.match?(URI::DEFAULT_PARSER.make_regexp)

          errors.add(:base, :invalid, message: "URL format is invalid")
          false
        end

        # validate URL scheme
        def valid_scheme?
          return true if %w[http https].include?(uri&.scheme&.to_s&.downcase)

          errors.add(:base, :invalid, message: "URL scheme is invalid. Only http and https are allowed.")
          false
        end

        # validate URL host
        def valid_host?
          return true unless uri&.host&.to_s&.strip&.empty?

          errors.add(:base, :invalid, message: "URL host is invalid")
          false
        end

        # prevent URL containing user info (username:password@), which is a security risk
        def no_user_info?
          return true if uri.userinfo.nil?

          errors.add(:base, :invalid, message: "URL must not contain user info")
          false
        end

        # prevent URL containing blocked host
        def not_blocked_host?
          return true unless blocked_host?(uri.host)

          errors.add(:base, :invalid, message: "URL host is blocked")
          false
        end

        def blocked_host?(host)
          host = host.to_s.downcase.strip

          blocked_names = %w[
            localhost
            0.0.0.0
          ]

          return true if blocked_names.include?(host)

          # prevent SSRF, user could shorten links to internal networks to attack internal systems
          ip = IPAddr.new(host)
          return true if ip.loopback?
          return true if ip.private?
          return true if ip.link_local?
          return true if ip.to_s == "0.0.0.0"
          return true if ip.to_s == "::"

          false
        rescue IPAddr::InvalidAddressError
          # Not an IP literal, could be a normal domain
          false
        end
      end
    end
  end
end
