module Types
  class RankingEntryType < Types::BaseObject
    description "Ranking entry"

    field :player_id, ID, null: false
    field :player_name, String, null: false
    field :correct_count, Integer, null: false, description: "正解数"
    field :total_answered, Integer, null: false, description: "回答数"
    field :rank, Integer, null: true, description: "順位（同点考慮）"
  end
end
