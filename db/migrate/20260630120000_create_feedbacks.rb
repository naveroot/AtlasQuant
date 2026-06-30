class CreateFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :feedbacks do |t|
      t.references :user, null: true, foreign_key: true
      t.text :message, null: false
      t.string :page_url

      t.timestamps
    end
  end
end
