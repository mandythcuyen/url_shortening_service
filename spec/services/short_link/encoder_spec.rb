require "rails_helper"

RSpec.describe Services::ShortLink::Encoder, type: :service do
  let(:result) { described_class.new(url: url, session_token: session_token).perform }
  let!(:url) { Faker::Internet.url }
  let(:session_token) { SecureRandom.hex(32) }

  context "when url is invalid" do
    [nil, "", "   ", "not-a-url", "ftp://x.com", "javascript:alert(1)",
     "data:text/html,x", "file:///etc/passwd", "//x.com", "http://"].each do |bad|
      it "rejects #{bad.inspect}" do
        service = described_class.new(url: bad, session_token: session_token)

        expect(service.perform).to be_nil
        expect(service).to be_failure
        expect(service.message).to eq("Invalid URL")
        expect(ShortLink.count).to eq(0)
      end
    end
  end

  context "when session token is blank" do
    it "rejects the request" do
      service = described_class.new(url: url, session_token: nil)

      expect(service.perform).to be_nil
      expect(service).to be_failure
      expect(service.message).to eq("Session token is required")
      expect(ShortLink.count).to eq(0)
    end
  end

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

    it "returns the short_url and warms the decode cache" do
      expect(result[:short_url]).to eq("#{ENV.fetch('HOST')}/#{result[:short_code]}")
      expect(Rails.cache.read("shortlink:decode:#{result[:short_code]}")).to eq(url)
    end

    it "retries with another short_code when the generated one is already taken" do
      taken = create(:short_link).short_code

      allow(SecureRandom).to receive(:alphanumeric).with(described_class::SHORT_CODE_LENGTH)
        .and_return(taken, "Uniq123")

      expect { result }.to change(ShortLink, :count).by(1)
      expect(result[:short_code]).to eq("Uniq123")
    end

    it "fails when every retry hits a collision" do
      taken = create(:short_link).short_code
      allow(SecureRandom).to receive(:alphanumeric).with(described_class::SHORT_CODE_LENGTH).and_return(taken)

      service = described_class.new(url: url, session_token: session_token)

      expect(service.perform).to be_nil
      expect(service).to be_failure
      expect(service.message).to eq("Failed to create short link after maximum retries")
    end
  end
end
