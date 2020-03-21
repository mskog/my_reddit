# frozen_string_literal: true

require "spec_helper"

describe MyReddit::API do
  include Rack::Test::Methods

  before :each do
    File.delete("ACCESS_TOKEN") if File.exist?("ACCESS_TOKEN")
  end

  after :each do
    File.delete("ACCESS_TOKEN") if File.exist?("ACCESS_TOKEN")
  end

  def app
    MyReddit::API
  end

  Given(:auth_headers) do
    {
      "Accept" => "*/*",
      "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
      "Authorization" => "bearer #{access_token}",
      "User-Agent" => "Faraday v0.9.2"
    }
  end

  describe "GET" do
    context "with valid authentication" do
      When do
        authorize ENV["AUTH_USERNAME"], ENV["AUTH_PASSWORD"]
        get "/r/top"
      end

      context "with no access token" do
        Given(:access_token){"foobar"}
        Given do
          stub_request(:post, "https://#{ENV['CLIENT_ID']}:#{ENV['CLIENT_SECRET']}@www.reddit.com/api/v1/access_token")
            .with(body: {"grant_type" => "refresh_token", "refresh_token" => (ENV["REFRESH_TOKEN"]).to_s})
            .to_return(status: 200, body: {"access_token" => access_token}.to_json, headers: {})
        end

        Given do
          stub_request(:get, "https://oauth.reddit.com//r/top")
            .with(headers: auth_headers)
            .to_return(status: 200, body: {foo: :bar}.to_json, headers: {})
        end

        Then{expect(JSON.parse(last_response.body)).to eq("foo" => "bar")}
      end

      context "with existing up to date access token" do
        Given(:access_token){"foobar"}

        Given do
          File.open("ACCESS_TOKEN", "w") do |file|
            file << access_token
          end
        end

        Given do
          stub_request(:get, "https://oauth.reddit.com//r/top")
            .with(headers: auth_headers)
            .to_return(status: 200, body: {foo: :bar}.to_json, headers: {})
        end

        Then{expect(JSON.parse(last_response.body)).to eq("foo" => "bar")}
      end

      context "with old access token" do
        Given(:access_token){"foobar"}

        Given do
          File.open("ACCESS_TOKEN", "w") do |file|
            file << access_token
          end
        end

        Given do
          allow(File).to receive(:stat).with("ACCESS_TOKEN").and_return(OpenStruct.new(mtime: Time.now - (3600 * 24)))
        end

        Given!(:access_token_stub) do
          stub_request(:post, "https://#{ENV['CLIENT_ID']}:#{ENV['CLIENT_SECRET']}@www.reddit.com/api/v1/access_token")
            .with(body: {"grant_type" => "refresh_token", "refresh_token" => (ENV["REFRESH_TOKEN"]).to_s})
            .to_return(status: 200, body: {"access_token" => access_token}.to_json, headers: {})
        end

        Given do
          stub_request(:get, "https://oauth.reddit.com//r/top")
            .with(headers: auth_headers)
            .to_return(status: 200, body: {foo: :bar}.to_json, headers: {})
        end

        Then{expect(JSON.parse(last_response.body)).to eq("foo" => "bar")}
        And{expect(access_token_stub).to have_been_requested}
      end
    end
  end

  describe "POST" do
    context "with valid authentication" do
      Given(:id){4}

      When do
        authorize ENV["AUTH_USERNAME"], ENV["AUTH_PASSWORD"]
        post "/api/unsave", id: id
      end

      context "with no access token" do
        Given(:access_token){"foobar"}
        Given do
          stub_request(:post, "https://#{ENV['CLIENT_ID']}:#{ENV['CLIENT_SECRET']}@www.reddit.com/api/v1/access_token")
            .with(body: {"grant_type" => "refresh_token", "refresh_token" => (ENV["REFRESH_TOKEN"]).to_s})
            .to_return(status: 200, body: {"access_token" => access_token}.to_json, headers: {})
        end

        Given do
          stub_request(:post, "https://oauth.reddit.com//api/unsave")
            .with(body: {"id" => "4"},
                  headers: auth_headers)
            .to_return(status: 200, body: "{}", headers: {})
        end

        Then {}
      end

      context "with existing up to date access token" do
        Given(:access_token){"foobar"}

        Given do
          File.open("ACCESS_TOKEN", "w") do |file|
            file << access_token
          end
        end

        Given do
          stub_request(:post, "https://oauth.reddit.com//api/unsave")
            .with(body: {"id" => "4"},
                  headers: auth_headers)
            .to_return(status: 200, body: "{}", headers: {})
        end

        Then {}
      end

      context "with old access token" do
        Given(:access_token){"foobar"}

        Given do
          File.open("ACCESS_TOKEN", "w") do |file|
            file << access_token
          end
        end

        Given do
          allow(File).to receive(:stat).with("ACCESS_TOKEN").and_return(OpenStruct.new(mtime: Time.now - (3600 * 24)))
        end

        Given!(:access_token_stub) do
          stub_request(:post, "https://#{ENV['CLIENT_ID']}:#{ENV['CLIENT_SECRET']}@www.reddit.com/api/v1/access_token")
            .with(body: {"grant_type" => "refresh_token", "refresh_token" => (ENV["REFRESH_TOKEN"]).to_s})
            .to_return(status: 200, body: {"access_token" => access_token}.to_json, headers: {})
        end

        Given do
          stub_request(:post, "https://oauth.reddit.com//api/unsave")
            .with(body: {"id" => id.to_s},
                  headers: auth_headers)
            .to_return(status: 200, body: "{}", headers: {})
        end

        Then{expect(access_token_stub).to have_been_requested}
      end
    end
  end
end
