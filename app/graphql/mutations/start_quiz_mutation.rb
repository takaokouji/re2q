module Mutations
  class StartQuizMutation < Mutations::BaseMutation
    description "クイズを開始する（管理者用）"

    field :current_quiz_state, Types::CurrentQuizStateType, null: false
    field :errors, [ String ], null: false

    def resolve
      require_admin!

      state = QuizStateManager.start_quiz

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
  end
end
