# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :start_question, mutation: Mutations::StartQuestionMutation
    field :submit_answer, mutation: Mutations::SubmitAnswerMutation
    field :admin_login, mutation: Mutations::AdminLoginMutation
    field :admin_logout, mutation: Mutations::AdminLogoutMutation
  end
end
