# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [ Types::NodeType, null: true ], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ ID ], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    field :me, Types::PlayerType, null: true, description: "現在のプレイヤー情報"

    def me
      context[:current_player]
    end

    # 現在のクイズ状態を取得
    field :current_quiz_state, Types::CurrentQuizStateType, null: false,
      description: "現在のクイズ状態"

    def current_quiz_state
      CurrentQuizState.instance
    end

    # 自分の回答履歴を取得（player_uuid from Cookie）
    field :my_answers, [ Types::AnswerType ], null: false,
      description: "自分の回答履歴"

    def my_answers
      player = context[:current_player]
      return [] unless player

      player.answers.includes(:question).order({ question: { position: :asc }, answered_at: :asc })
    end

    # ランキングを取得 (Issue #13)
    field :ranking, [ Types::RankingEntryType ], null: false,
      description: "現在のランキング（正解数順）" do
        argument :lottery, Boolean, required: false, default_value: false, description: "同点の場合に抽選を行うかどうか"
      end

    def ranking(lottery:)
      RankingCalculator.calculate(lottery:)
    end

    # 現在ログイン中の管理者を取得
    field :current_admin, Types::AdminType, null: true,
      description: "現在ログイン中の管理者"

    def current_admin
      return nil unless context[:controller].session[:admin_id]
      Admin.find_by(id: context[:controller].session[:admin_id])
    end

    # 全質問一覧を取得（管理者用）
    field :questions, [ Types::QuestionType ], null: false,
      description: "全質問一覧（管理者用）"

    def questions
      # TODO: 管理者認証チェック
      Question.order(:position)
    end
  end
end
