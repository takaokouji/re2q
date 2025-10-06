class CreateCurrentQuizStates < ActiveRecord::Migration[8.0]
  def change
    create_table :current_quiz_states do |t|
      t.integer :active_question_id
      t.datetime :question_started_at
      t.integer :duration_seconds
      t.datetime :question_ends_at
      t.string :persist_job_id
      t.boolean :quiz_active, default: false, null: false

      t.timestamps
    end

    add_foreign_key :current_quiz_states, :questions, column: :active_question_id
    add_index :current_quiz_states, :id, unique: true
  end
end
