require 'swagger_helper'

describe 'Redirects', type: :request, swagger_doc: 'v1/swagger.yaml' do
  include_context :short_link_data

  path '/{short_code}' do
    parameter name: 'short_code', in: :path, type: :string
    
    get 'Redirect to original URL' do
      tags 'Redirects'
      consumes "application/json"
      produces "application/json"
      security [Bearer: [], key: []]
      parameter({
        name:   :short_code, 
        in:     :path, 
        type:   :string,
        required: true,
        description: 'The short code to redirect'
      })
      
      response '301', 'Redirect successful' do
        let(:short_code) { short_link.short_code }
        
        # puts JSON.pretty_generate(JSON.parse(response.body))
        run_test! do |response|
          expect(response).to have_http_status(301)
          expect(response.location).to eq(short_link.original_url)
        end
      end
      
      response '404', 'Short code not found' do
        let(:short_code) { 'nonexistent' }

        run_test! do |response|
          expect(response).to have_http_status(404)
          expect(response.body).to include('Not found or unsafe URL')
        end
      end

      response '404', 'Unsafe URL' do
        let(:short_code) do
          create(:short_link, original_url: 'ftp://example.com/file').short_code
        end

        run_test! do |response|
          expect(response).to have_http_status(404)
          expect(response.body).to include('Not found or unsafe URL')
        end
      end
    end
  end
end
