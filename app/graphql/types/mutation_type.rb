# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :start_question, mutation: Mutations::StartQuestionMutation
    field :submit_answer, mutation: Mutations::SubmitAnswerMutation
  end
end
