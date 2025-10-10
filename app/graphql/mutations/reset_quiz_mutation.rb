# frozen_string_literal: true

module Mutations
  class ResetQuizMutation < BaseMutation
    description "クイズ全体をリセット（回答、プレイヤー、状態を初期化）"

    field :success, Boolean, null: false
    field :deleted_answers_count, Integer, null: false
    field :deleted_players_count, Integer, null: false
    field :errors, [ String ], null: false

    def resolve
      require_admin!

      ActiveRecord::Base.transaction do
        # Count before deletion
        answers_count = Answer.count
        players_count = Player.count

        # Reset quiz state
        state = CurrentQuizState.instance
        state.update!(
          quiz_active: false,
          question_id: nil,
          question_started_at: nil,
          question_ends_at: nil,
          duration_seconds: nil
        )

        # Delete all answers and players
        Answer.delete_all
        Player.delete_all

        {
          success: true,
          deleted_answers_count: answers_count,
          deleted_players_count: players_count,
          errors: []
        }
      end
    rescue GraphQL::ExecutionError => e
      {
        success: false,
        deleted_answers_count: 0,
        deleted_players_count: 0,
        errors: [ e.message ]
      }
    rescue StandardError => e
      {
        success: false,
        deleted_answers_count: 0,
        deleted_players_count: 0,
        errors: [ e.message ]
      }
    end
  end
end
