class DeleteLegacyClientApplications < ActiveRecord::Migration[8.0]
  def change
    drop_table :oauth_client_applications, if_exists: true
  end
end
