class CreateQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :questions do |t|
      t.text :content, null: false
      t.boolean :correct_answer, null: false
      t.integer :duration_seconds, null: false, default: 15
      t.integer :position, null: false

      t.timestamps
    end
    add_index :questions, :position, unique: true
  end
end
