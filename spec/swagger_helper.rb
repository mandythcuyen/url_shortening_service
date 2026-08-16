# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1',
        description: 'URL shortening service'
      },
      paths: {},
      servers: [
        {
          url:         "http://localhost:3000",
          variables:   {
            endPoint: {
              default: "http://localhost:3000",
            },
          },
          description: "localhost",
        },
        {
          url:         "https://staging.mandyseeyoo.com",
          variables:   {
            endPoint: {
              default: "https://staging.mandyseeyoo.com",
            },
          },
          description: "staging",
        },
      ],
      components: {
        schemas: {
          UrlPayload: {
            type: :object,
            properties: {
              url: { type: :string, format: :uri, example: 'https://codesubmit.io/library/react' }
            },
            required: ['url']
          },
          EncodeResult: {
            type: :object,
            properties: {
              short_code: { type: :string, example: 'GeAi9K' },
              short_url: { type: :string, format: :uri, example: 'https://mandyseeyoo.com/GeAi9K' }
            },
            required: ['short_code', 'short_url']
          },
          DecodeResult: {
            type: :object,
            properties: {
              short_code: { type: :string, example: 'GeAi9K' },
              original_url: { type: :string, format: :uri, example: 'https://codesubmit.io/library/react' }
            },
            required: ['short_code', 'original_url']
          },
          Error: {
            type: :object,
            properties: {
              error: { type: :string, example: 'Short code not found' }
            }
          },
          ValidationErrors: {
            type: :object,
            properties: {
              errors: {
                type: :array,
                items: { type: :string, example: 'URL scheme is invalid. Only http and https are allowed.' }
              }
            },
            required: ['errors']
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
