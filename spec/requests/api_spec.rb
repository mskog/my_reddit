require 'spec_helper'

describe MyReddit::API do
  include Rack::Test::Methods

  before :each do
    File.delete('ACCESS_TOKEN') if File.exists?('ACCESS_TOKEN')
  end

  after :each do
    File.delete('ACCESS_TOKEN') if File.exists?('ACCESS_TOKEN')
  end

  def app
    MyReddit::API
  end

  describe "GET" do
    context "with valid authentication" do
      When do
        authorize ENV['AUTH_USERNAME'], ENV['AUTH_PASSWORD']
        get "/r/top"
      end

      context "with no access token" do
        Given(:access_token){'foobar'}
        Given do
          stub_request(:post, "https://#{ENV['CLIENT_ID']}:#{ENV['CLIENT_SECRET']}@www.reddit.com/api/v1/access_token").
            with(:body => {"grant_type"=>"refresh_token", "refresh_token"=>"#{ENV['REFRESH_TOKEN']}"}).
            to_return(:status => 200, :body => {'access_token' => access_token}.to_json, :headers => {})
        end

        Given do
          stub_request(:get, "https://oauth.reddit.com//r/top").
           with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>"bearer #{access_token}", 'User-Agent'=>'Faraday v0.9.2'}).
           to_return(:status => 200, :body => {foo: :bar}.to_json, :headers => {})
        end

        Then{expect(JSON.parse(last_response.body)).to eq("foo" => "bar")}
      end
    end
  end
end