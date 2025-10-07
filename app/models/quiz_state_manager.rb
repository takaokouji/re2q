class QuizStateManager
  class << self
    # 質問を開始 (Issue #9)
    def start_question(question_id)
      state = CurrentQuizState.instance
      question = Question.find(question_id)

      raise "Quiz is not active" unless state.quiz_active?
      raise "Another question is already active" if state.question_active?

      now = Time.current
      ends_at = now + question.duration_seconds.seconds

      # Issue #11 - 永続化Jobをキック（question_ends_atまで1秒間隔でループ実行し自動停止）
      PersistAnswersJob.perform_later(question_id)

      state.update!(
        question_id:,
        question_started_at: now,
        duration_seconds: question.duration_seconds,
        question_ends_at: ends_at
      )

      state
    end

    # 質問を強制終了 (Issue #12)
    def stop_question
      state = CurrentQuizState.instance
      return state unless state.question_id.present?

      # question_ends_atを現在時刻にすることで、PersistAnswersJobが自動停止
      state.update!(
        question_ends_at: Time.current
      )

      state
    end

    # クイズ全体を開始
    def start_quiz
      state = CurrentQuizState.instance
      state.update!(quiz_active: true)
      state
    end

    # クイズ全体を終了
    def stop_quiz
      stop_question if CurrentQuizState.instance.active_question_id.present?
      state = CurrentQuizState.instance
      state.update!(quiz_active: false)
      state
    end

    # 現在の状態を取得
    def current_state
      CurrentQuizState.instance
    end

    # 回答受付可能かチェック (Issue #10)
    def accepting_answers?
      CurrentQuizState.instance.accepting_answers?
    end

    # 現在の質問IDを取得（回答受付時に使用）
    def current_question_id
      state = CurrentQuizState.instance
      state.accepting_answers? ? state.question_id : nil
    end
  end
end
