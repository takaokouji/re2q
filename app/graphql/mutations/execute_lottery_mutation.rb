module Mutations
  class ExecuteLotteryMutation < BaseMutation
    description "Execute lottery for tied players"

    field :ranking_entries, [ Types::RankingEntryType ], null: false, description: "Updated ranking entries after lottery"
    field :errors, [ String ], null: false

    def resolve
      require_admin!

      # Trigger the lottery logic and get updated rankings
      ranking_entries = RankingCalculator.calculate_with_lottery

      { ranking_entries: ranking_entries, errors: [] }
    end
  end
end
