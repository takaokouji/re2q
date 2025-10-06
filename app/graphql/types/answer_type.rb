module Types
  class AnswerType < Types::BaseObject
    global_id_field :id
    field :player_id, ID, null: false
    field :question_id, ID, null: false
    field :player_answer, Boolean, null: false
    field :answered_at, GraphQL::Types::ISO8601DateTime, null: false
    field :question, Types::QuestionType, null: false
    field :is_correct, Boolean, null: false, description: "正解かどうか"

    def is_correct
      object.player_answer == object.question.correct_answer
    end
  end
end
