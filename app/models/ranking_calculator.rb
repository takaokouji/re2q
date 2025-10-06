class RankingCalculator
  class << self
    def calculate
      # Answerテーブルから正解数を集計
      results = Answer.joins(:question, :player)
        .select(
          "players.id as player_id",
          "players.uuid as player_uuid",
          "COUNT(*) as total_answered",
          "SUM(CASE WHEN answers.player_answer = questions.correct_answer THEN 1 ELSE 0 END) as correct_count"
        )
        .group("players.id", "players.uuid")
        .order("correct_count DESC, total_answered ASC")
        .map do |result|
          {
            player_id: result.player_id,
            player_uuid: result.player_uuid,
            correct_count: result.correct_count,
            total_answered: result.total_answered,
            rank: nil  # あとで計算
          }
        end

      # 順位を計算（同点の場合は同順位）
      current_rank = 1
      previous_correct_count = nil
      results.each_with_index do |entry, index|
        if previous_correct_count != entry[:correct_count]
          current_rank = index + 1
        end
        entry[:rank] = current_rank
        previous_correct_count = entry[:correct_count]
      end

      results.map { |r| OpenStruct.new(r) }
    end
  end
end
