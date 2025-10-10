# frozen_string_literal: true

class PersistAnswersJob < ApplicationJob
  queue_as :default

  # Issue #11: Solid Cache から回答データを読み出し、DB に永続化する Job
  # 1秒間隔でループ実行し、question_ends_at を過ぎたら自動停止
  def perform(question_id)
    state = CurrentQuizState.instance

    # 質問が終了していないかチェック
    if state.question_id != question_id || !state.accepting_answers?
      # 最後の永続化処理を実行してから終了
      PersistAnswers.call(question_id: question_id)
      return
    end

    # Solid Cache から回答を読み出して DB に永続化
    PersistAnswers.call(question_id: question_id)

    # 1秒後に再実行
    PersistAnswersJob.set(wait: 1.second).perform_later(question_id)
  end
end
