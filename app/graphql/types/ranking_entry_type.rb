module Types
  class RankingEntryType < Types::BaseObject
    description "Ranking entry"

    global_id_field :player_id
    field :player_uuid, String, null: false
    field :correct_count, Integer, null: false, description: "正解数"
    field :total_answered, Integer, null: false, description: "回答数"
    field :rank, Integer, null: true, description: "順位（同点考慮）"
  end
end
