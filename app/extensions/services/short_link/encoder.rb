module Services
  module ShortLink
    class Encoder < Services::BaseService
      SHORT_CODE_LENGTH = 7.freeze
      MAX_RETRIES = 3.freeze
      CACHE_EXPIRATION = 30.days.freeze
      
      def self.call(url:, session_token:)
        new(url:, session_token:).perform
      end

      attr_reader :url, :session_token
    
      def initialize(url:, session_token:)
        @url = url.to_s.strip
        @session_token = session_token.to_s
      end

      def perform
        return fail! 'Invalid URL' unless valid_url?
        return fail! 'Session token is required' if session_token.blank?

        # Check cache first
        cached_short_code = Rails.cache.read(encode_cache_key)
        return success! (payload(cached_short_code)) if cached_short_code.present?

        # Cache miss - check database
        existing = ::ShortLink.find_by(session_token: session_token, original_url_hash: url_hash)
        if existing
          # Found in database, write to cache then return
          write_cache(existing)
          return success! payload(existing.short_code)
        end

        # Not found, create new
        new_link = create_with_retry
        write_cache(new_link)

        success! payload(new_link.short_code)
      rescue StandardError => e
        fail! e.message, e
      end

      private

      def valid_url?
        return false if url.blank? || !url.match?(URI::DEFAULT_PARSER.make_regexp)
        
        uri = URI.parse(url)

        %w[http https].include?(uri.scheme&.to_s&.downcase) && uri.host.present?
      rescue URI::InvalidURIError
        false
      end

      def generate_short_code
        SecureRandom.alphanumeric(SHORT_CODE_LENGTH)
      end
 
      def create_with_retry
        retries = 0
        loop do
          short_code = generate_short_code

          begin
            return ::ShortLink.create!(session_token: session_token, original_url: url, short_code: short_code)
          rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
            retries += 1
            raise "Failed to create short link after maximum retries" if retries >= MAX_RETRIES
          end
        end
      end

      def write_cache(link)
        # Cache encode: session + url → short_code
        # Help user get short code quickly when they enter the same URL in the same session
        Rails.cache.write(encode_cache_key, link.short_code, expires_in: CACHE_EXPIRATION)

        # Cache decode: short_code → original_url
        # Help redirect/decode quickly and reduce PostgreSQL load
        Rails.cache.write(decode_cache_key(link.short_code), link.original_url, expires_in: CACHE_EXPIRATION)
      end

      def payload(short_code)
        short_url = "#{host}/#{short_code}"

        {
          short_code: short_code,
          short_url: short_url,
        }
      end

      def host
        ENV.fetch("HOST")
      end

      def url_hash
        @url_hash ||= ::ShortLink.hash_url(url)
      end
 
      def encode_cache_key
        "shortlink:encode:#{session_token}:#{url_hash}"
      end
      
      def decode_cache_key(short_code)
        "shortlink:decode:#{short_code}"
      end
    end
  end
end
