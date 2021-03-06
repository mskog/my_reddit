# frozen_string_literal: true

require "uri"
require "faraday"
require "dotenv/load"

# configure{ set :server, :puma }

module MyReddit
  class API < Grape::API
    format :json

    http_basic do |username, password|
      { ENV["AUTH_USERNAME"] => ENV["AUTH_PASSWORD"] }[username] == password
    end

    get "*" do
      params = request.params
      params.delete("splat")
      Reddit.new.get(request.path, params)
    end

    post "*" do
      params = request.params
      params.delete("splat")
      Reddit.new.post(request.path, params)
    end
  end

  class Reddit
    def get(url, params)
      JSON.parse(Faraday.get("https://oauth.reddit.com/" + url, params) do |request|
        request.headers["Authorization"] = "bearer #{access_token}"
      end.body)
    end

    def post(url, params)
      JSON.parse(Faraday.post("https://oauth.reddit.com/" + url) do |request|
        request.headers["Authorization"] = "bearer #{access_token}"
        request.body = params
      end.body)
    end

    private

    def refresh_token_if_necessary
      return if File.exist?("ACCESS_TOKEN") && (Time.now - File.stat("ACCESS_TOKEN").mtime) / 60 < 45

      connection = Faraday.new("https://www.reddit.com/api/v1/")
      connection.basic_auth(ENV["CLIENT_ID"], ENV["CLIENT_SECRET"])
      response = connection.post("access_token", grant_type: "refresh_token", refresh_token: ENV["REFRESH_TOKEN"])
      File.open("ACCESS_TOKEN", "w") do |file|
        file << JSON.parse(response.body)["access_token"]
      end
    end

    def access_token
      refresh_token_if_necessary
      File.read("ACCESS_TOKEN")
    end
  end
end
