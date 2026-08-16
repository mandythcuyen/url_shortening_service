# TODO: Add last_accessed_at and click_count for analytics and cleanup
class CreateShortLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :short_links do |t|
      t.text :original_url, null: false
      t.string :short_code, null: false, limit: 10
      t.string :session_token, null: false
      # Use hash to reduce the size of the index in case original_url is too long
      t.string :original_url_hash, null: false, limit: 64
      

      t.timestamps
    end

    # Short code is unique globally, lookup primary
    add_index :short_links, :short_code, unique: true, name: "index_short_links_on_short_code"
    # Same session + same URL → same short code
    add_index :short_links, [:session_token, :original_url_hash], unique: true, name: "index_short_links_on_session_token_and_original_url_hash"
  end
end
