module Types
  class QuestionType < Types::BaseObject
    field :id, ID, null: false
    field :content, String, null: false
    field :correct_answer, Boolean, null: false
    field :duration_seconds, Integer, null: false
    field :position, Integer, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
