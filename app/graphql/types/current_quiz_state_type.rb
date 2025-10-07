module Types
  class CurrentQuizStateType < Types::BaseObject
    description "Current quiz state"

    global_id_field :id
    field :quiz_active, Boolean, null: false, description: "クイズ全体がアクティブか"
    field :question_started_at, GraphQL::Types::ISO8601DateTime, null: true
    field :question_ends_at, GraphQL::Types::ISO8601DateTime, null: true
    field :duration_seconds, Integer, null: true
    field :question_active, Boolean, null: false, description: "質問が受付中か"
    field :remaining_seconds, Integer, null: false, description: "残り時間（秒）"
    field :question, Types::QuestionType, null: true

    def question_active
      object.question_active?
    end

    def remaining_seconds
      object.remaining_seconds
    end
  end
end
