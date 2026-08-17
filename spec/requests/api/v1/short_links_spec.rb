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
        schema '$ref' => '#/components/schemas/short_link'

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
        schema '$ref' => '#/components/schemas/error'

        let(:payload) { 
          { 
              url: 'invalid_url' 
            } 
          }

        run_test! do |response|
          expect(response).to have_http_status(422)
          response_body = JSON.parse(response.body)
          puts JSON.pretty_generate(response_body)
          expect(response_body["errors"]).to include("URL format is invalid")
        end
      end
    end
  end
end
