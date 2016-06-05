require 'uri'
require 'faraday'

module MyReddit
  class API < Grape::API
    format :json

    get "*" do
      "Hello World"
    end
  end
end
