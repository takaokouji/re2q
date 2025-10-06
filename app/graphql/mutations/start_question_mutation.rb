module Mutations
  class StartQuestionMutation < Mutations::BaseMutation
    description "質問を開始する（管理者用）"

    argument :question_id, ID, required: true

    field :current_quiz_state, Types::CurrentQuizStateType, null: false
    field :errors, [ String ], null: false

    def resolve(question_id:)
      # TODO: 管理者認証チェック

      state = QuizStateManager.start_question(question_id)

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
