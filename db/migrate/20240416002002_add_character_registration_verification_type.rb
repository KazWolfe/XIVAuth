class AddCharacterRegistrationVerificationType < ActiveRecord::Migration[7.1]
  def change
    add_column :character_registrations, :extra_data, :jsonb
    add_column :character_registrations, :source, :string, null: false, default: "internal"
    add_column :character_registrations, :verification_type, :string

    reversible do |dir|
      dir.up do
        CharacterRegistration.verified.update_all(verification_type: 'lodestone_code')
      end
    end
  end
end
