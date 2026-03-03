class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.inherited(child_class)
    super

    if child_class.column_names.include?("created_at")
      child_class.implicit_order_column = "created_at"
    end
  end

  before_create :generate_uuidv7

  private def generate_uuidv7
    return if self.class.attribute_types["id"].type != :uuid ||
              self.class.columns_hash["id"].default_function != "gen_random_uuid()"

    self.id ||= SecureRandom.uuid_v7
  end
end
