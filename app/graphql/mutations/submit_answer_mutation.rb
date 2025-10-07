module Mutations
  class SubmitAnswerMutation < Mutations::BaseMutation
    description "回答を送信する（利用者用）"

    argument :answer, Boolean, required: true, description: "◯ (true) or ✗ (false)"

    field :errors, [ String ], null: false

    def resolve(answer:)
      player = context[:current_player]
      raise "Player not found" unless player

      # 受付可能かチェック
      question_id = QuizStateManager.current_question_id
      raise "No active question" unless question_id

      # Solid Cacheに書き込み（Key: "answer:#{question_id}:#{player.id}"）
      cache_key = "answer:#{question_id}:#{player.id}"
      Rails.cache.write(cache_key, {
        player_id: player.id,
        question_id: question_id,
        player_answer: answer,
        answered_at: Time.current.iso8601
      }, expires_in: 1.hour)

      # キーリストに追加（PersistAnswersJob が使用）
      key_list_key = "answer_keys:#{question_id}"
      answer_keys = Rails.cache.read(key_list_key) || []
      answer_keys << cache_key unless answer_keys.include?(cache_key)
      Rails.cache.write(key_list_key, answer_keys, expires_in: 1.hour)

      {
        errors: []
      }
    rescue StandardError => e
      {
        errors: [ e.message ]
      }
    end
  end
end
