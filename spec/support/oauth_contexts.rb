RSpec.shared_context "oauth:user_credentials" do
  # Allow specs to override any of these with their own let blocks.
  let(:user) { FactoryBot.create(:user) }
  let(:oauth_client) { FactoryBot.create(:oauth_client) }
  let(:oauth_scopes) { "" }

  let(:oauth_token) do
    OAuth::AccessToken.create!(application: oauth_client, resource_owner: user, scopes: oauth_scopes)
  end

  let(:bearer_token) { "Bearer #{oauth_token.token}" }
end

RSpec.shared_context "oauth:client_credentials" do
  let(:oauth_client) { FactoryBot.create(:oauth_client, grant_flows: ["client_credentials"]) }
  let(:oauth_token) { OAuth::AccessToken.create!(application: oauth_client, scopes: "") }

  let(:bearer_token) { "Bearer #{oauth_token.token}" }
end
