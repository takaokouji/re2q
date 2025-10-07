# frozen_string_literal: true

class GraphqlController < ApplicationController
  # CSRF protection exemption for GraphQL API
  # Cookie-based authentication is still functional
  skip_before_action :verify_authenticity_token

  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]

    # Cookie から player を取得または作成
    player = find_or_create_player_from_cookie

    context = {
      current_player: player,
      player_uuid: player.uuid  # 後方互換性のため残す
    }

    result = Re2qSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?
    handle_error_in_development(e)
  end

  private

  # Cookie から player を取得または作成
  def find_or_create_player_from_cookie
    player_uuid = cookies.encrypted[:player_uuid]

    if player_uuid.blank?
      # 新規 Player を作成
      player = Player.create!(uuid: SecureRandom.uuid)
      cookies.encrypted[:player_uuid] = {
        value: player.uuid,
        expires: 1.day.from_now,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax  # クロスオリジンリクエストでもcookieを送信可能に
      }
      player
    else
      # 既存の Player を取得（存在しない場合は新規作成）
      player = Player.find_by(uuid: player_uuid)
      if player.nil?
        player = Player.create!(uuid: SecureRandom.uuid)
        cookies.encrypted[:player_uuid] = {
          value: player.uuid,
          expires: 1.day.from_now,
          httponly: true,
          secure: Rails.env.production?,
          same_site: :lax  # クロスオリジンリクエストでもcookieを送信可能に
        }
      end
      player
    end
  end

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")

    render json: { errors: [ { message: e.message, backtrace: e.backtrace } ], data: {} }, status: 500
  end
end
