# frozen_string_literal: true

module Mutations
  class AdminLogoutMutation < BaseMutation
    field :success, Boolean, null: false

    def resolve
      context[:controller].session[:admin_id] = nil
      { success: true }
    end
  end
end
