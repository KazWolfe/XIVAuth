class AddCertificateTypesToPKI < ActiveRecord::Migration[8.0]
  def up
    # 1. Create the new enum
    create_enum "pki_certificate_type", %w[character_identification user_identification code_signing]

    # 2. Add certificate_type column to issued certificates (nullable initially for backfill)
    add_column :pki_issued_certificates, :certificate_type, :enum,
               enum_type: "pki_certificate_type"

    # 3. Backfill certificate_type from subject_type
    execute <<~SQL
      UPDATE pki_issued_certificates
      SET certificate_type = CASE subject_type
        WHEN 'User' THEN 'user_identification'::pki_certificate_type
        WHEN 'CharacterRegistration' THEN 'character_identification'::pki_certificate_type
      END
    SQL

    # 4. Make certificate_type NOT NULL after backfill
    change_column_null :pki_issued_certificates, :certificate_type, false

    # 5. Rename allowed_subject_types → allowed_certificate_types and change its enum type
    #    We need to drop and re-add since we're changing the enum type
    remove_column :pki_certificate_authorities, :allowed_subject_types

    add_column :pki_certificate_authorities, :allowed_certificate_types, :enum,
               enum_type: "pki_certificate_type",
               array: true,
               null: false,
               default: %w[]

    # 6. Drop the old enum (no longer used by any column)
    drop_enum "pki_subject_type"
  end

  def down
    # 1. Recreate the old enum
    create_enum "pki_subject_type", %w[user character_registration]

    # 2. Restore allowed_subject_types
    remove_column :pki_certificate_authorities, :allowed_certificate_types

    add_column :pki_certificate_authorities, :allowed_subject_types, :enum,
               enum_type: "pki_subject_type",
               array: true,
               null: false,
               default: %w[user character_registration]

    # 3. Drop certificate_type column
    remove_column :pki_issued_certificates, :certificate_type

    # 4. Drop the new enum
    drop_enum "pki_certificate_type"
  end
end
