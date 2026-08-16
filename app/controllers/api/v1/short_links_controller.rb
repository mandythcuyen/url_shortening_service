module Api
  module V1
    class ShortLinksController < ApplicationController
      def encode
        form = Api::Forms::ShortLinks::Encode.new(
          session_token: session_token_from_cookie,
          **encode_params
        )

        result = Api::UseCases::ShortLinks::Encode.call(form)
        if result.success?
          # resource = result.value!.short_link
          # render json: json_resource_with_serializer(resource: resource)
        else
          # render json: Errors::ActiveRecordValidation.new(result.failure, "short_links").to_hash,
          #          status: :unprocessable_entity
        end
      end

      private

      def encode_params
        params.permit(:url)
      end
    end
  end
end
