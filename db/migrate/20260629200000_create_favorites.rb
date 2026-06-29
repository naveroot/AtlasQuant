class CreateFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.string :secid, null: false

      t.timestamps
    end

    add_index :favorites, [ :user_id, :secid ], unique: true
  end
end
