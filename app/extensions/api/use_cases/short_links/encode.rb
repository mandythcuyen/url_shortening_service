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
          encoder = Services::ShortLink::Encoder.new(url: form.url, session_token: form.session_token)

          encoder.perform
          
          encoder.success? ? success(form) : failure(form)
        end
      end
    end
  end
end
