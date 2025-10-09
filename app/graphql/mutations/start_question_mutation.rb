module Mutations
  class StartQuestionMutation < Mutations::BaseMutation
    description "質問を開始する（管理者用）"

    argument :question_id, ID, required: true, loads: Types::QuestionType, as: :target_question

    field :current_quiz_state, Types::CurrentQuizStateType, null: false
    field :errors, [ String ], null: false

    def resolve(target_question:)
      unless context[:current_admin]
        raise GraphQL::ExecutionError, "You must be an admin to perform this action"
      end

      state = QuizStateManager.start_question(target_question.id)

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
