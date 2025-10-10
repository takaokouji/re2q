class CreateFinalRankings < ActiveRecord::Migration[8.0]
  def change
    create_table :final_rankings do |t|
      t.references :player, null: false, foreign_key: true
      t.integer :rank, null: false
      t.integer :correct_count, null: false, default: 0
      t.integer :total_answered, null: false, default: 0
      t.integer :lottery_score, null: false, default: 0

      t.timestamps
    end
  end
end
