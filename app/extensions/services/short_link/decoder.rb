module Services
  module ShortLink
    class Decoder < Services::BaseService
      CACHE_EXPIRATION = 30.days.freeze

      attr_reader :short_code, :rails_cache

      def initialize(short_code:, rails_cache: Rails.cache)
        @short_code = short_code
        @rails_cache = rails_cache
      end

      def perform
        return nil unless valid_format?

        # try to get from cache first (O(1) lookup)
        cached_url = rails_cache.read(decode_cache_key(short_code))
        return cached_url if cached_url.present?

        # fallback to database query, just pick the original_url column
        original_url = ::ShortLink.where(short_code: short_code).pick(:original_url)

        # if found, cache it
        rails_cache.write(decode_cache_key(short_code), original_url, expires_in: CACHE_EXPIRATION) if original_url

        original_url
      end

      private

        def valid_format?
          code = @short_code.to_s

          code.match?(/\A[A-Za-z0-9]+\z/) && code.length.between?(4, 10)
        end

        def decode_cache_key(short_code)
          "shortlink:decode:#{short_code}"
        end
    end
  end
end
