# frozen_string_literal: true

class PersistAnswersJob < ApplicationJob
  queue_as :default

  # Issue #11: Solid Cache から回答データを読み出し、DB に永続化する Job
  # 1秒間隔でループ実行し、question_ends_at を過ぎたら自動停止
  def perform(question_id)
    state = CurrentQuizState.instance
    question = Question.find(question_id)

    # 質問が終了していないかチェック
    if state.active_question_id != question_id || Time.current >= state.question_ends_at
      # 最後の永続化処理を実行してから終了
      persist_cached_answers(question_id)
      clear_question_state(state, question_id)
      return
    end

    # Solid Cache から回答を読み出して DB に永続化
    persist_cached_answers(question_id)

    # 1秒後に再実行
    PersistAnswersJob.set(wait: 1.second).perform_later(question_id)
  end

  private

  def persist_cached_answers(question_id)
    # Solid Cache のキーパターン: "answer:#{question_id}:#{player_id}"
    # Redis の KEYS コマンド相当の機能は Solid Cache にないため、
    # 回答済みプレイヤーを別途管理する必要がある
    # ここでは、受付期間中の全プレイヤーのキーをチェックする方式を採用

    # キャッシュから回答を収集
    cached_answers = collect_cached_answers(question_id)
    return if cached_answers.empty?

    # DB に一括挿入（重複は無視）
    bulk_insert_answers(cached_answers)

    # キャッシュから削除（永続化完了後）
    delete_cached_answers(cached_answers, question_id)
  end

  def collect_cached_answers(question_id)
    # Player全体をスキャンするのではなく、キャッシュキーのリストを別途保持
    # キーリスト: "answer_keys:#{question_id}" (Set型)
    key_list_key = "answer_keys:#{question_id}"
    answer_keys = Rails.cache.read(key_list_key) || []

    cached_answers = []
    answer_keys.each do |cache_key|
      data = Rails.cache.read(cache_key)
      cached_answers << data if data
    end

    cached_answers
  end

  def bulk_insert_answers(cached_answers)
    # 重複チェック: player_id と question_id の組み合わせでユニーク制約があるため
    # insert_all で on_duplicate: :skip を使用
    Answer.insert_all(
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
    # ユニーク制約違反は無視（既に挿入済み）
  end

  def delete_cached_answers(cached_answers, question_id)
    cached_answers.each do |data|
      cache_key = "answer:#{question_id}:#{data[:player_id]}"
      Rails.cache.delete(cache_key)
    end

    # キーリストもクリア
    key_list_key = "answer_keys:#{question_id}"
    Rails.cache.delete(key_list_key)
  end

  def clear_question_state(state, question_id)
    # Issue #12: 永続化Job終了後、CurrentQuizState をクリア
    # active_question_id が現在の question_id と一致する場合のみクリア
    if state.active_question_id == question_id
      state.update!(
        active_question_id: nil,
        question_started_at: nil,
        question_ends_at: nil,
        duration_seconds: nil
      )
    end
  end
end
