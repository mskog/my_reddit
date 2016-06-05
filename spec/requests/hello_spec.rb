require 'spec_helper'

describe MyReddit::API do
  include Rack::Test::Methods

  def app
    MyReddit::API
  end

  describe "Hello" do

    When{get "/"}

    context "with valid parameters" do
      Then{expect(last_response.status).to eq 200}
      And{expect(last_response.body).to eq "\"Hello world\""}
    end
  end
end
