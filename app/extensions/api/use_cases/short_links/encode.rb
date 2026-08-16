module Api
  module UseCases
    module ShortLinks
      class Encode < UseCases::Base
        check :valid?

        db do
          step :persist
        end

        private

          def valid?(form, **)
            form.valid?
          end

          def persist(form, **)
            encoder_service = Services::ShortLink::Encoder
              .new(url: form.url, session_token: form.session_token)

            short_link_payload = encoder_service.perform

            encoder_service.success? ? success(short_link_payload) : failure(form)
          end
      end
    end
  end
end
