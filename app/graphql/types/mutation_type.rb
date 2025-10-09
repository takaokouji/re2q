# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :start_question, mutation: Mutations::StartQuestionMutation
    field :submit_answer, mutation: Mutations::SubmitAnswerMutation
    field :admin_login, mutation: Mutations::AdminLoginMutation
    field :admin_logout, mutation: Mutations::AdminLogoutMutation
    field :reset_all_player_sessions, mutation: Mutations::ResetAllPlayerSessionsMutation
    field :execute_lottery, mutation: Mutations::ExecuteLotteryMutation
  end
end
