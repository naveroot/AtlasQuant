class CreateFavoriteInstruments < ActiveRecord::Migration[8.1]
  def change
    create_table :favorite_instruments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :secid, null: false
      t.string :shortname, null: false
      t.string :asset_code, null: false

      t.timestamps
    end

    add_index :favorite_instruments, [ :user_id, :secid ], unique: true
  end
end
