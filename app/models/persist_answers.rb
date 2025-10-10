# frozen_string_literal: true

# Solid Cache から回答データを読み出し、DB に永続化するモデル
# 最後の回答を採用する（回答を更新可能にする）
class PersistAnswers
  def self.call(question_id:)
    new(question_id: question_id).call
  end

  def initialize(question_id:)
    @question_id = question_id
  end

  def call
    # キャッシュから回答を収集
    cached_answers = collect_cached_answers
    return if cached_answers.empty?

    # DB に一括保存（既存の回答は更新）
    upsert_answers(cached_answers)

    # キャッシュから削除（永続化完了後）
    delete_cached_answers(cached_answers)
  end

  private

  attr_reader :question_id

  def collect_cached_answers
    # キーリスト: "answer_keys:#{question_id}" (Array型)
    key_list_key = "answer_keys:#{question_id}"
    answer_keys = Rails.cache.read(key_list_key) || []

    cached_answers = []
    answer_keys.each do |cache_key|
      data = Rails.cache.read(cache_key)
      cached_answers << data if data
    end

    cached_answers
  end

  def upsert_answers(cached_answers)
    # upsert_all を使用して、既存の回答を更新
    # 最後の回答を採用するため、常に更新する
    Answer.upsert_all(
      cached_answers.map { |data|
        {
          player_id: data[:player_id],
          question_id: data[:question_id],
          player_answer: data[:player_answer],
          answered_at: Time.zone.parse(data[:answered_at]),
          created_at: Time.current,
          updated_at: Time.current
        }
      },
      unique_by: [ :player_id, :question_id ]
    )
  rescue ActiveRecord::RecordNotUnique
    # ユニーク制約違反は無視（念のため）
  end

  def delete_cached_answers(cached_answers)
    cached_answers.each do |data|
      cache_key = "answer:#{question_id}:#{data[:player_id]}"
      Rails.cache.delete(cache_key)
    end

    # キーリストもクリア
    key_list_key = "answer_keys:#{question_id}"
    Rails.cache.delete(key_list_key)
  end
end
