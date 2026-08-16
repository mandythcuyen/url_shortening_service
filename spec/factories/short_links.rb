FactoryBot.define do
  factory :short_link do
    original_url { Faker::Internet.url }
    short_code { SecureRandom.alphanumeric(7) }
    session_token { SecureRandom.hex(32) }
    original_url_hash { Digest::SHA256.hexdigest(original_url) }
  end
end
