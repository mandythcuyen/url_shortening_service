require 'swagger_helper'

RSpec.describe 'Redirects', type: :request do
  path '/{short_code}' do
    get 'Redirects a short code to its original URL' do
      tags 'Redirect'
      description 'Responds with a 301 to the original URL, or 404 when the short code is unknown or points to an unsafe URL.'
      parameter name: :short_code, in: :path, type: :string, required: true,
                description: 'Short code, 4 to 10 alphanumeric characters', example: 'GeAi9K'

      response '301', 'redirects to the original URL' do
        header 'Location', schema: { type: :string, format: :uri }, description: 'Original URL'

        let(:short_link) { create(:short_link, original_url: 'https://codesubmit.io/library/react') }
        let(:short_code) { short_link.short_code }

        run_test! do |response|
          expect(response.headers['Location']).to eq('https://codesubmit.io/library/react')
        end
      end

      response '404', 'short code not found or unsafe URL' do
        let(:short_code) { 'ZZZZZZ' }

        run_test! do |response|
          expect(response.body).to eq('Not found or unsafe URL')
        end
      end
    end
  end

  describe 'GET /:short_code' do
    it 'returns 404 when the stored URL is unsafe' do
      short_link = build(:short_link, original_url: 'ftp://example.com/file')
      short_link.save!(validate: false)

      get "/#{short_link.short_code}"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to eq('Not found or unsafe URL')
    end

    it 'does not route short codes with an invalid format' do
      get '/abc'
      expect(response).to have_http_status(:not_found)

      get '/with-dash'
      expect(response).to have_http_status(:not_found)
    end
  end
end
