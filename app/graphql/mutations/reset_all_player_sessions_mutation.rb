# frozen_string_literal: true

module Mutations
  class ResetAllPlayerSessionsMutation < BaseMutation
    description "全利用者のセッションをリセットする（管理者用）"

    field :success, Boolean, null: false
    field :deleted_count, Integer, null: false
    field :errors, [ String ], null: false

    def resolve
      require_admin!

      deleted_count = Player.count
      Player.destroy_all

      {
        success: true,
        deleted_count: deleted_count,
        errors: []
      }
    rescue GraphQL::ExecutionError => e
      {
        success: false,
        deleted_count: 0,
        errors: [ e.message ]
      }
    rescue StandardError => e
      {
        success: false,
        deleted_count: 0,
        errors: [ "セッションのリセットに失敗しました: #{e.message}" ]
      }
    end
  end
end
