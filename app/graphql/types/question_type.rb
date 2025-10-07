module Types
  class QuestionType < Types::BaseObject
    global_id_field :id
    field :content, String, null: false
    field :correct_answer, Boolean, null: false
    field :duration_seconds, Integer, null: false
    field :position, Integer, null: false
    field :question_number, Integer, null: false, description: "問題番号（position と同じ）"
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    def question_number
      object.position
    end
  end
end
