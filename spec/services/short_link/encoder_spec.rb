require "rails_helper"

RSpec.describe Services::ShortLink::Encoder, type: :service do
  let(:result) { described_class.new(url: url, session_token: session_token).perform }
  let(:url) { Faker::Internet.url }
  let(:session_token) { SecureRandom.hex(32) }

  context "when cache has short_code" do
    let!(:link) { create(:short_link, session_token: session_token, original_url: url) }

    before do
      # Mock cache read to return the short_code
      allow(Rails.cache).to receive(:read).with("shortlink:encode:#{session_token}:#{Digest::SHA256.hexdigest(url)}").and_return(link.short_code)
    end

    it "return short_code from cache when user sends the same URL" do
      # Verify that cache write is not called
      expect(Rails.cache).not_to receive(:write).with("shortlink:encode:#{session_token}:#{Digest::SHA256.hexdigest(url)}", anything)

      expect(result[:short_code]).to eq(link.short_code)
      expect(ShortLink.count).to eq(1)
    end
  end

  context "when cache does not have short_code, but found in database" do
    let!(:link) { create(:short_link, session_token: session_token, original_url: url) }

    it "caches it and returns the short_code" do
      expect(result[:short_code]).to eq(link.short_code)

      cache_key = "shortlink:encode:#{session_token}:#{Digest::SHA256.hexdigest(url)}"
      expect(Rails.cache.read(cache_key)).to eq(result[:short_code])

      expect(ShortLink.count).to eq(1)
    end
  end


  context "when cache does not have short_code and not found in database" do
    it "creates a new short link and caches it" do
      expect { result }.to change(ShortLink, :count).by(1)
 
      cache_key = "shortlink:encode:#{session_token}:#{Digest::SHA256.hexdigest(url)}"
      expect(Rails.cache).not_to receive(:write).with(cache_key, anything)
      expect(Rails.cache.read(cache_key)).to eq(result[:short_code])
    end
  end
end
