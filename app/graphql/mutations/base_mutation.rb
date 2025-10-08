# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    argument_class Types::BaseArgument
    field_class Types::BaseField
    input_object_class Types::BaseInputObject
    object_class Types::BaseObject

    protected

    # 管理者認証チェック
    # @return [Admin, nil] 認証済みの管理者、または nil
    def current_admin
      # テスト環境用のコンテキストを優先
      return context[:current_admin] if context[:current_admin].present?

      return nil unless context[:controller]

      admin_id = context[:controller].session[:admin_id]
      return nil unless admin_id

      @current_admin ||= Admin.find_by(id: admin_id)
    end

    # 管理者認証を要求
    # @raise [GraphQL::ExecutionError] 認証されていない場合
    def require_admin!
      unless current_admin
        raise GraphQL::ExecutionError, "管理者認証が必要です"
      end
    end
  end
end
