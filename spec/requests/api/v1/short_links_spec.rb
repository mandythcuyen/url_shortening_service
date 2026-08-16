require 'swagger_helper'

RSpec.describe 'Api::V1::ShortLinks', type: :request do
  path '/api/v1/encode' do
    post 'Shortens an original URL' do
      tags 'Short links'
      description 'Returns a short code for the given URL. The same URL sent twice within a session returns the same short code.'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :payload, in: :body, schema: { '$ref' => '#/components/schemas/UrlPayload' }

      response '200', 'short link created' do
        schema '$ref' => '#/components/schemas/EncodeResult'

        let(:payload) { { url: 'https://codesubmit.io/library/react' } }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['short_code']).to match(/\A[A-Za-z0-9]{7}\z/)
          expect(body['short_url']).to eq("#{ENV.fetch('HOST')}/#{body['short_code']}")
          expect(ShortLink.find_by(short_code: body['short_code']).original_url)
            .to eq('https://codesubmit.io/library/react')
        end
      end

      response '422', 'invalid URL' do
        schema '$ref' => '#/components/schemas/ValidationErrors'

        let(:payload) { { url: 'javascript:alert(1)' } }

        run_test! do |response|
          expect(JSON.parse(response.body)['errors'])
            .to include('URL scheme is invalid. Only http and https are allowed.')
          expect(ShortLink.count).to eq(0)
        end
      end
    end
  end

  describe 'POST /api/v1/encode' do
    let(:url) { 'https://codesubmit.io/library/react' }

    it 'returns the same short code when the same URL is shortened twice in one session' do
      post '/api/v1/encode', params: { url: url }, as: :json
      first_short_code = JSON.parse(response.body)['short_code']

      expect {
        post '/api/v1/encode', params: { url: url }, as: :json
      }.not_to change(ShortLink, :count)

      expect(JSON.parse(response.body)['short_code']).to eq(first_short_code)
    end

    it 'returns a different short code for another session' do
      post '/api/v1/encode', params: { url: url }, as: :json
      first_short_code = JSON.parse(response.body)['short_code']

      cookies.delete('_short_link_session')

      expect {
        post '/api/v1/encode', params: { url: url }, as: :json
      }.to change(ShortLink, :count).by(1)

      expect(JSON.parse(response.body)['short_code']).not_to eq(first_short_code)
    end

    {
      'blank url' => ['', "Url can't be blank"],
      'malformed url' => ['not-a-url', 'URL format is invalid'],
      'url with user info' => ['https://user:pass@example.com', 'URL must not contain user info'],
      'loopback host (SSRF)' => ['http://127.0.0.1/admin', 'URL host is blocked'],
      'localhost' => ['http://localhost:3000/admin', 'URL host is blocked'],
      'private network host (SSRF)' => ['http://192.168.0.1/', 'URL host is blocked'],
      'too long url' => ["https://example.com/#{'a' * 2048}", 'URL is too long']
    }.each do |label, (invalid_url, message)|
      it "rejects #{label} with 422" do
        post '/api/v1/encode', params: { url: invalid_url }, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['errors']).to include(message)
        expect(ShortLink.count).to eq(0)
      end
    end
  end

  path '/api/v1/decode/{short_code}' do
    get 'Resolves a short code back to its original URL' do
      tags 'Short links'
      produces 'application/json'
      parameter name: :short_code, in: :path, type: :string, required: true,
                description: 'Short code, 4 to 10 alphanumeric characters', example: 'GeAi9K'

      response '200', 'original URL found' do
        schema '$ref' => '#/components/schemas/DecodeResult'

        let(:short_link) { create(:short_link, original_url: 'https://codesubmit.io/library/react') }
        let(:short_code) { short_link.short_code }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['short_code']).to eq(short_link.short_code)
          expect(body['original_url']).to eq('https://codesubmit.io/library/react')
        end
      end

      response '404', 'short code not found' do
        schema '$ref' => '#/components/schemas/Error'

        let(:short_code) { 'ZZZZZZ' }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('Short code not found')
        end
      end
    end
  end

  describe 'GET /api/v1/decode/:short_code' do
    it 'serves the original URL from cache without hitting the database' do
      short_link = create(:short_link)

      get "/api/v1/decode/#{short_link.short_code}"
      expect(response).to have_http_status(:ok)

      expect(ShortLink).not_to receive(:where)
      get "/api/v1/decode/#{short_link.short_code}"

      expect(JSON.parse(response.body)['original_url']).to eq(short_link.original_url)
    end

    it 'does not route short codes with an invalid format' do
      get '/api/v1/decode/abc'
      expect(response).to have_http_status(:not_found)

      get '/api/v1/decode/with-dash'
      expect(response).to have_http_status(:not_found)
    end
  end
end
