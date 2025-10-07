module Types
  class AnswerType < Types::BaseObject
    global_id_field :id
    global_id_field :player_id
    global_id_field :question_id
    field :player_answer, Boolean, null: false
    field :answered_at, GraphQL::Types::ISO8601DateTime, null: false
    field :question, Types::QuestionType, null: false
    field :is_correct, Boolean, null: false, description: "正解かどうか"

    def is_correct
      object.player_answer == object.question.correct_answer
    end
  end
end
