# frozen_string_literal: true

# PlayerAuthentication concern
#
# Cookie-based Player authentication for re2q application.
# Automatically creates a Player record and sets an encrypted cookie
# for anonymous user tracking.
#
# Usage:
#   class MyController < ApplicationController
#     include PlayerAuthentication
#
#     def index
#       player = find_or_create_player_from_cookie
#       # or use current_player after calling ensure_player_authenticated
#     end
#   end
module PlayerAuthentication
  extend ActiveSupport::Concern

  included do
    # Optional: uncomment to automatically authenticate on all actions
    # before_action :ensure_player_authenticated
  end

  # Get or create player from cookie and set as current_player
  def ensure_player_authenticated
    @current_player = find_or_create_player_from_cookie
  end

  # Returns the authenticated player (call ensure_player_authenticated first)
  def current_player
    @current_player
  end

  private

  # Cookie から player を取得または作成
  def find_or_create_player_from_cookie
    player_uuid = cookies.encrypted[:player_uuid]

    if player_uuid.blank?
      # 新規 Player を作成
      create_new_player
    else
      # 既存の Player を取得（存在しない場合は新規作成）
      find_existing_player_or_create(player_uuid)
    end
  end

  # 新規 Player を作成し、Cookie を設定
  def create_new_player
    player = Player.create!(uuid: SecureRandom.uuid)
    set_player_cookie(player.uuid)
    player
  end

  # 既存の Player を取得、存在しない場合は新規作成
  def find_existing_player_or_create(player_uuid)
    player = Player.find_by(uuid: player_uuid)
    if player.nil?
      player = Player.create!(uuid: SecureRandom.uuid)
      set_player_cookie(player.uuid)
    end
    player
  end

  # Player Cookie を設定
  def set_player_cookie(player_uuid)
    cookies.encrypted[:player_uuid] = {
      value: player_uuid,
      expires: 1.day.from_now,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax  # クロスオリジンリクエストでもcookieを送信可能に
    }
  end
end
