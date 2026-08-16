class ShortLink < ApplicationRecord
  validates :original_url, presence: true, length: { maximum: 2048 }
  validates :short_code, presence: true, uniqueness: true, length: { in: 4..10 }
  validates :session_token, presence: true
  validates :short_code, format: { with: /\A[a-zA-Z0-9]+\z/, message: "only alphanumeric characters allowed" }

  def self.hash_url(url)
    # SHA-256 → 64 characters, stable, conflict-free
    Digest::SHA256.hexdigest(url.to_s.strip) 
  end

  before_validation :set_original_url_hash, on: :create

  private

  def set_original_url_hash
    self.original_url_hash = self.class.hash_url(original_url)
  end
end
