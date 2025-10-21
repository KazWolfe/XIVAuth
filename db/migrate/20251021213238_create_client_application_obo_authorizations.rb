class CreateClientApplicationOboAuthorizations < ActiveRecord::Migration[8.0]
  def change
    create_table :client_application_obo_authorizations, id: false do |t|
      t.belongs_to :audience, type: :uuid, null: false, foreign_key: { to_table: :client_applications }
      t.belongs_to :authorized_party, type: :uuid, null: false, foreign_key: { to_table: :client_applications }
    end
  end
end
