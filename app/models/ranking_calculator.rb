class RankingCalculator
  class << self
    def calculate(lottery: false)
      results = fetch_raw_ranking_data

      if lottery
        tied_groups = find_tied_players(results)
        tied_groups.each do |group|
          group.shuffle.each.with_index(1) do |player_data, index|
            player_data[:lottery_score] = index
          end
        end

        # Re-sort results to apply lottery tie-breaker
        results.sort_by! do |entry|
          [ -entry[:correct_count], entry[:lottery_score] ]
        end
      end

      # 順位を計算（同点の場合は同順位）
      current_rank = 1
      previous_correct_count = nil
      previous_lottery_score = nil

      results.each_with_index do |entry, index|
        if previous_correct_count != entry[:correct_count] ||
           previous_lottery_score != entry[:lottery_score]
          current_rank = index + 1
        end
        entry[:rank] = current_rank
        previous_correct_count = entry[:correct_count]
        previous_lottery_score = entry[:lottery_score]
      end

      results.map { |r| RankingEntry.new(**r) }
    end

    private

    def fetch_raw_ranking_data
      Answer.joins(:question, :player)
        .select(
          "players.id as player_id",
          "players.uuid as player_uuid",
          "COUNT(*) as total_answered",
          "SUM(CASE WHEN answers.player_answer = questions.correct_answer THEN 1 ELSE 0 END) as correct_count"
        )
        .group("players.id", "players.uuid")
        .order("correct_count DESC, total_answered ASC")
        .map do |result|
          player = Player.new(id: result.player_id, uuid: result.player_uuid)
          {
            player_id: player.to_gid_param,
            player_name: player.name,
            correct_count: result.correct_count,
            total_answered: result.total_answered,
            rank: nil,  # あとで計算
            lottery_score: 0 # Initialize lottery score
          }
        end
    end

    def find_tied_players(results)
      results.group_by { |r| [ r[:correct_count] ] }
        .values
        .select { |group| group.size > 1 }
    end

    def apply_lottery_tie_breaker(tied_players_group)
      tied_players_group.sample
    end
  end
end
