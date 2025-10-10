module Mutations
  class StopQuizMutation < Mutations::BaseMutation
    description "クイズを停止する（管理者用）"

    field :current_quiz_state, Types::CurrentQuizStateType, null: false
    field :errors, [ String ], null: false

    def resolve
      require_admin!

      state = QuizStateManager.stop_quiz

      # ランキングを計算して永続化
      persist_final_ranking

      {
        current_quiz_state: state,
        errors: []
      }
    rescue StandardError => e
      {
        current_quiz_state: CurrentQuizState.instance,
        errors: [ e.message ]
      }
    end

    private

    def persist_final_ranking
      # 既存のランキングをクリア
      FinalRanking.clear_all

      # ランキングを計算（抽選あり）
      ranking_entries = RankingCalculator.calculate(lottery: true)

      # FinalRanking に保存
      ranking_entries.each do |entry|
        player = GlobalID::Locator.locate(entry.player_id)
        FinalRanking.create!(
          player: player,
          rank: entry.rank,
          correct_count: entry.correct_count,
          total_answered: entry.total_answered,
          lottery_score: entry.lottery_score
        )
      end
    end
  end
end
