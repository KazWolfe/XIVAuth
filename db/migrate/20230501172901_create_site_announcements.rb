class CreateSiteAnnouncements < ActiveRecord::Migration[7.0]
  def change
    create_table :site_announcements, id: :uuid do |t|
      t.text :type # success, info, notice, warning, danger

      t.text :title
      t.text :body

      t.datetime :start_date
      t.datetime :end_date, null: true

      t.timestamps
    end
  end
end
