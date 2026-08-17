require 'swagger_helper'

describe 'Api::V1::ShortLinks', type: :request, swagger_doc: 'v1/swagger.yaml' do
  path '/api/v1/encode' do
    post "shortens an original URL" do
      tags "ShortLinks"
      consumes "application/json"
      produces "application/json"
      # Parameter for the request body
      parameter name: :payload, 
                in: :body, 
                schema: {
                  type: :object,
                  properties: {
                    url: { type: :string, format: :uri, example: 'https://example.com' }
                  },
                  required: ['url']
                }
      # Context
      response "200", "when shortening successfully" do
        schema '$ref' => '#/components/schemas/encode_response'

        let(:payload) { 
          { 
              url: 'https://example.com' 
            } 

          }

        run_test! do |response|
          expect(response).to have_http_status(200)
          response_body = JSON.parse(response.body)
          expect(response_body["short_code"]).to be_present
          expect(response_body["short_url"]).to be_present
        end
      end

      response "422", "when shortening fails" do
        schema '$ref' => '#/components/schemas/errors'

        let(:payload) { 
          { 
              url: 'invalid_url' 
            } 
          }

        run_test! do |response|
          expect(response).to have_http_status(422)
          response_body = JSON.parse(response.body)
          expect(response_body["errors"]).to include("URL format is invalid")
        end
      end
    end
  end

  path "/api/v1/decode/{short_code}" do
    get "decodes a short code back to the original URL" do
      tags "ShortLinks"
      produces "application/json"
      parameter name: :short_code, 
                in: :path, 
                type: :string, 
                required: true,
                description: "Short code, 4 to 10 alphanumeric characters",
                example: "GeAi9KU"

      response "200", "when decoding successfully" do
        schema '$ref' => '#/components/schemas/decode_response'

        let(:short_code) { "GeAi9KU" }
        let!(:short_link) { create(:short_link, short_code: short_code, original_url: 'https://example.com') }

        run_test! do |response|
          expect(response).to have_http_status(200)
          response_body = JSON.parse(response.body)
          expect(response_body["original_url"]).to be_present
          expect(response_body["short_code"]).to eq("GeAi9KU")
        end
      end

      response "404", "when short code not found" do
        schema '$ref' => '#/components/schemas/error'

        let(:short_code) { "NONONO" }

        run_test! do |response|
          expect(response).to have_http_status(404)
          response_body = JSON.parse(response.body)
          expect(response_body["error"]).to include("Short code not found")
        end
      end
    end
  end
end
