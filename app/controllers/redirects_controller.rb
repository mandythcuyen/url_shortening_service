class RedirectsController < ApplicationController
  def show
    original_url = Services::ShortLink::Decoder
    .new(short_code: params[:short_code])
    .perform

    if original_url && safe_url?(original_url)
      redirect_to original_url, allow_other_host: true, status: :moved_permanently
    else
      render plain: "Not found or unsafe URL", status: :not_found
    end
  end

  private

    # TODO: Move to concern object
    def safe_url?(url)
      uri = URI.parse(url)
      return false unless %w[http https].include?(uri.scheme&.downcase)
      return false if uri.host.blank?
      return false if uri.userinfo.present? # https://user:pass@site.com

      true
    rescue URI::InvalidURIError
      false
    end
end
