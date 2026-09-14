require "rails_helper"

describe "GET /embed_check" do
  it "returns embeddable: false for invalid urls" do
    get embed_check_path, params: { url: "not a url" }

    expect(response).to have_http_status(:success)
    expect(JSON.parse(response.body)).to eq("embeddable" => false)
  end

  it "returns embeddable: false for localhost" do
    get embed_check_path, params: { url: "http://127.0.0.1/foo" }

    expect(JSON.parse(response.body)).to eq("embeddable" => false)
  end

  it "returns embeddable: false when X-Frame-Options blocks" do
    response_double = instance_double(Net::HTTPOK, is_a?: true, :[] => nil)
    allow(response_double).to receive(:[]).with("x-frame-options").and_return("DENY")
    allow(response_double).to receive(:[]).with("content-security-policy").and_return(nil)
    allow_any_instance_of(EmbedCheckController).to receive(:fetch_headers).and_return(response_double)

    get embed_check_path, params: { url: "https://example.com/" }

    expect(JSON.parse(response.body)).to eq("embeddable" => false)
  end

  it "returns embeddable: false when CSP frame-ancestors blocks" do
    response_double = double("response")
    allow(response_double).to receive(:[]).with("x-frame-options").and_return(nil)
    allow(response_double).to receive(:[]).with("content-security-policy").and_return("frame-ancestors 'none'")
    allow_any_instance_of(EmbedCheckController).to receive(:fetch_headers).and_return(response_double)

    get embed_check_path, params: { url: "https://example.com/" }

    expect(JSON.parse(response.body)).to eq("embeddable" => false)
  end

  it "returns embeddable: true when no blocking headers are set" do
    response_double = double("response")
    allow(response_double).to receive(:[]).and_return(nil)
    allow_any_instance_of(EmbedCheckController).to receive(:fetch_headers).and_return(response_double)

    get embed_check_path, params: { url: "https://example.com/" }

    expect(JSON.parse(response.body)).to eq("embeddable" => true)
  end
end
