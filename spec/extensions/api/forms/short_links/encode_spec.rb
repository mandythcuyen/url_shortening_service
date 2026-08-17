require "rails_helper"

RSpec.describe Api::Forms::ShortLinks::Encode, type: :form do
  let(:params) {
    {
      "url" => "https://example.com",
    }
  }
  let(:session_token) { "session_token" }

  subject do
    described_class.new(
      session_token: session_token,
      **params.to_h.symbolize_keys,
    )
  end

  describe "initialize" do
    context "when url is blank" do
      let(:params) {
        {
          "url" => "",
        }
      }
      it { expect(subject).not_to be_valid }
    end

    context "when session_token is blank" do
      let(:session_token) { "" }
      it { expect(subject).not_to be_valid }
    end

    context "when both url and session_token have valid values" do
      it { expect(subject).to be_valid }
    end
  end

  describe "validations" do
    context "when url is blank" do
      let(:params) {
        {
          "url" => "",
        }
      }
      it do
        subject.valid?
        expect(subject.errors[:url]).to include("can't be blank")
      end
    end

    context "when url is invalid" do
      [nil, "", "   ", "not-a-url", "ftp://x.com", "javascript:alert(1)",
      "data:text/html,x", "file:///etc/passwd", "//x.com", "http://"].each do |bad|
        it "rejects #{bad.inspect}" do
          subject = described_class.new(
            session_token: session_token,
            url: bad,
          )
          expect(subject).not_to be_valid
        end
      end
    end

    context "when url has invalid length" do
      let(:params) {
        {
          "url" => "https://example.com" * 200, # 200 * 19 = 3800 characters
        }
      }
      it do
        subject.valid?
        expect(subject.errors[:base]).to include("URL is too long")
      end
    end

    context "when url has invalid format" do
      let(:params) {
        {
          "url" => "<script>alert(1)</script>",
        }
      }
      it do
        subject.valid?
        # puts subject.errors[:base]
        expect(subject.errors[:base]).to include("URL format is invalid")
      end
    end

    context "when url has invalid scheme" do
      let(:params) {
        {
          "url" => "ftp://example.com",
        }
      }
      it do
        subject.valid?
        expect(subject.errors[:base]).to include("URL scheme is invalid. Only http and https are allowed.")
      end
    end

    context "when url has invalid host" do
      let(:params) {
        {
          "url" => "https://",
        }
      }
      it do
        subject.valid?
        expect(subject.errors[:base]).to include("URL host is invalid")
      end
    end

    context "when url has user info" do
      let(:params) {
        {
          "url" => "https://user:pass@example.com",
        }
      }
      it do
        subject.valid?
        expect(subject.errors[:base]).to include("URL must not contain user info")
      end
    end

    context "when url has blocked host" do
      let(:params) {
        {
          "url" => "https://#{%w[localhost 0.0.0.0 ::1 192.168.0.1].sample}",
        }
      }
      it do
        subject.valid?
        expect(subject.errors[:base]).to include("URL host is blocked")
      end
    end
  end
end
