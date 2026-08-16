class ApplicationController < ActionController::Base
  include ActionController::Cookies

  private

    # Get or create a session token from cookie
    def session_token_from_cookie
      token = cookies.signed["_short_link_session"]

      # Generate a new session token if it doesn't exist (first visit)
      if token.blank?
        token = SecureRandom.alphanumeric(32)

        cookies.signed[:_short_link_session] = {
          value:     token,
          httponly:  true,
          secure:    Rails.env.production?,
          same_site: :lax,
          expires:   1.year.from_now,
        }
      end

      token
    end
end
