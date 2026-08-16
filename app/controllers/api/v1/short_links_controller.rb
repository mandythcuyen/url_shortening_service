module Api
  module V1
    class ShortLinksController < ApplicationController
      def encode
        form = Api::Forms::ShortLinks::Encode.new(
          session_token: session_token_from_cookie,
          **encode_params.to_h.symbolize_keys
        )

        result = Api::UseCases::ShortLinks::Encode.call(form)
        if result.success?
          render json: result.value!, status: :ok
        else
          render json: { errors: form.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def decode
        original_url = Services::ShortLink::Decoder.new(short_code: params[:short_code]).perform

        if original_url
          render json: { original_url: original_url, short_code: params[:short_code] }, status: :ok
        else
          render json: { error: "Short code not found" }, status: :not_found
        end
      end

      private

        def encode_params
          params.permit(:url)
        end
    end
  end
end
