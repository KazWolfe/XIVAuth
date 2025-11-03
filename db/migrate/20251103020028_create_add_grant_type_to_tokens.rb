class CreateAddGrantTypeToTokens < ActiveRecord::Migration[8.1]
  def change
    add_column :oauth_access_tokens, :source_grant_flow, :string, null: true
  end
end
