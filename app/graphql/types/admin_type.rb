# frozen_string_literal: true

module Types
  class AdminType < Types::BaseObject
    global_id_field :id
    field :username, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
