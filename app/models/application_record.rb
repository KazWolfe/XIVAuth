class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  before_create :generate_uuidv7

  private def generate_uuidv7
    return if self.class.attribute_types["id"].type != :uuid ||
              self.class.columns_hash["id"].default_function != "gen_random_uuid()"

    self.id ||= SecureRandom.uuid_v7
  end
end
