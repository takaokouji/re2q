module Mutations
  class StartNextQuestionMutation < Mutations::BaseMutation
    description "次の質問を自動的に開始する（管理者用）"

    field :current_quiz_state, Types::CurrentQuizStateType, null: false
    field :is_last_question, Boolean, null: false, description: "開始した問題が最後の問題かどうか"
    field :errors, [ String ], null: false

    def resolve
      require_admin!

      state = CurrentQuizState.instance
      current_question = state.question

      # 現在の問題がない場合は、最初の問題を開始
      if current_question.nil?
        next_question = Question.order(:position).first
        raise "No questions available" if next_question.nil?
      else
        # 次の問題を取得
        next_question = Question.where("position > ?", current_question.position).order(:position).first
        raise "No more questions available" if next_question.nil?
      end

      # 次の問題を開始
      updated_state = QuizStateManager.start_question(next_question.id)

      # さらに次の問題が存在するかチェック
      following_question = Question.where("position > ?", next_question.position).order(:position).first
      is_last = following_question.nil?

      {
        current_quiz_state: updated_state,
        is_last_question: is_last,
        errors: []
      }
    rescue StandardError => e
      {
        current_quiz_state: CurrentQuizState.instance,
        is_last_question: false,
        errors: [ e.message ]
      }
    end
  end
end
