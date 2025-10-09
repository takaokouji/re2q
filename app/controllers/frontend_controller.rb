# frozen_string_literal: true

class FrontendController < ApplicationController
  include PlayerAuthentication

  # /frontend/admin 以外のアクセス時に Player を認証
  before_action :authenticate_player_for_non_admin, only: [:show]

  def show
    render file: Rails.root.join("public", "frontend", "frontend-index.html"), layout: false
  end

  private

  # /admin パス以外の場合に Player 認証を実行
  def authenticate_player_for_non_admin
    # /frontend/admin へのアクセスは認証をスキップ
    return if request.path.start_with?("/frontend/admin")

    # Player を取得または作成し、Cookie を設定
    ensure_player_authenticated
  end
end
