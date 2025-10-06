class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.string :uuid, null: false

      t.timestamps
    end
    add_index :players, :uuid, unique: true
  end
end
