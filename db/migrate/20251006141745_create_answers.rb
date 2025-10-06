class CreateAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :answers do |t|
      t.references :player, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.boolean :player_answer, null: false
      t.datetime :answered_at, null: false

      t.timestamps
    end
    add_index :answers, [ :player_id, :question_id ], unique: true
    add_index :answers, :answered_at
  end
end
