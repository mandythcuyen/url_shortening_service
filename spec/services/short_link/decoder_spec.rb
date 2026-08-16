require "rails_helper"

RSpec.describe Services::ShortLink::Decoder, type: :service do
  let(:result) { described_class.new(short_code: short_code).perform }
  let(:short_code) { link.short_code }
  let!(:link) { create(:short_link) }

  def cache_key(code)
    "shortlink:decode:#{code}"
  end

  context "when short_code format is invalid" do
    [nil, "", "abc", "a" * 11, "with-dash", "abc def", "Ábcdef", 123].each do |bad|
      it "rejects #{bad.inspect} without touching cache or database" do
        expect(Rails.cache).not_to receive(:read)
        expect(ShortLink).not_to receive(:where)

        expect(described_class.new(short_code: bad).perform).to be_nil
      end
    end
  end

  context "when cache has the original_url" do
    before { Rails.cache.write(cache_key(short_code), "https://cached.example.com") }

    it "returns the cached url without querying the database" do
      expect(ShortLink).not_to receive(:where)

      expect(result).to eq("https://cached.example.com")
    end
  end

  context "when cache does not have the original_url, but found in database" do
    it "caches it and returns the original_url" do
      expect(result).to eq(link.original_url)
      expect(Rails.cache.read(cache_key(short_code))).to eq(link.original_url)
    end
  end

  context "when short_code is not found anywhere" do
    let(:short_code) { "ZZZZZZ" }

    it "returns nil and does not cache the miss" do
      expect(result).to be_nil
      expect(Rails.cache.read(cache_key(short_code))).to be_nil
    end
  end

  context "when a custom cache store is injected" do
    let(:rails_cache) { ActiveSupport::Cache::MemoryStore.new }

    it "reads from and writes to the injected store" do
      expect(Rails.cache).not_to receive(:read)

      expect(described_class.new(short_code: short_code, rails_cache: rails_cache).perform)
        .to eq(link.original_url)
      expect(rails_cache.read(cache_key(short_code))).to eq(link.original_url)
    end
  end
end
