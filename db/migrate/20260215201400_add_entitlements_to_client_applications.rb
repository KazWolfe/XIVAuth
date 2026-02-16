class AddEntitlementsToClientApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :client_applications, :entitlements, :string, array: true, null: false, default: []
  end
end
