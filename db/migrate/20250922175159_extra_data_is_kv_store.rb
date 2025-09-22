class ExtraDataIsKvStore < ActiveRecord::Migration[8.0]
  def change
    change_column_default :character_registrations, :extra_data, from: nil, to: { }
    change_column_null :character_registrations, :extra_data, false, { }
  end
end
