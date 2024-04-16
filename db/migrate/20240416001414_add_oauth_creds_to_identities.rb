class AddOAuthCredsToIdentities < ActiveRecord::Migration[7.1]
  def change
    # Adds an access/refresh token pair to Social Identities so that they can be used by
    # other application components.
    add_column :users_social_identities, :access_token, :string
    add_column :users_social_identities, :refresh_token, :string
  end
end
