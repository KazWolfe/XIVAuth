class CreateOAuthPermissibles < ActiveRecord::Migration[7.0]
  def change
    create_table :oauth_permissible_policies, id: :uuid do |t|
      t.datetime :created_at, null: false
    end

    create_table :oauth_permissible_rules, id: :uuid do |t|
      t.references :policy, type: :uuid, foreign_key: { to_table: :oauth_permissible_policies }

      t.boolean :deny, default: false
      t.references :resource, type: :string, polymorphic: true, null: true, index: true

      t.datetime :created_at, null: false
    end

    add_reference :oauth_access_grants, :permissible_policy,
                  null: true, type: :uuid, foreign_key: { to_table: :oauth_permissible_policies }
    add_reference :oauth_access_tokens, :permissible_policy,
                  null: true, type: :uuid, foreign_key: { to_table: :oauth_permissible_policies }
  end
end
