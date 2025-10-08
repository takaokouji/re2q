# frozen_string_literal: true

module Mutations
  class AdminLoginMutation < BaseMutation
    argument :username, String, required: true
    argument :password, String, required: true

    field :admin, Types::AdminType, null: true
    field :errors, [ String ], null: false

    def resolve(username:, password:)
      admin = Admin.find_by(username: username)

      if admin&.authenticate(password)
        context[:controller].session[:admin_id] = admin.id
        { admin: admin, errors: [] }
      else
        { admin: nil, errors: [ "ユーザー名またはパスワードが正しくありません" ] }
      end
    end
  end
end
