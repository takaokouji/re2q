# frozen_string_literal: true

require "test_helper"

class PersistAnswersJobTest < ActiveJob::TestCase
  setup do
    @question = create(:question)
    @state = CurrentQuizState.instance
    # テスト用のアダプターを設定
    ActiveJob::Base.queue_adapter = :test
  end

  test "calls PersistAnswers.call with question_id" do
    # 質問が終了している状態をセット（再実行されないように）
    @state.update!(question_id: nil)

    # PersistAnswers.call が呼ばれることを確認
    called_with = nil
    PersistAnswers.stub :call, ->(args) { called_with = args } do
      PersistAnswersJob.perform_now(@question.id)
    end

    assert_equal({ question_id: @question.id }, called_with)
  end

  test "schedules next job when question is still accepting answers" do
    # 質問受付中の状態をセット
    @state.update!(
      quiz_active: true,
      question_id: @question.id,
      question_started_at: Time.current,
      question_ends_at: 10.seconds.from_now
    )

    # 次のジョブがスケジュールされることを確認
    PersistAnswers.stub :call, nil do
      assert_enqueued_with(job: PersistAnswersJob, args: [ @question.id ], at: 1.second.from_now) do
        PersistAnswersJob.perform_now(@question.id)
      end
    end
  end

  test "does not schedule next job when question is no longer accepting answers" do
    # 質問が終了している状態をセット
    @state.update!(question_id: nil)

    # 次のジョブがスケジュールされないことを確認
    PersistAnswers.stub :call, nil do
      assert_no_enqueued_jobs do
        PersistAnswersJob.perform_now(@question.id)
      end
    end
  end

  test "does not schedule next job when question_id has changed" do
    # 別の質問に切り替わった状態をセット
    other_question = create(:question)
    @state.update!(
      quiz_active: true,
      question_id: other_question.id,
      question_started_at: Time.current,
      question_ends_at: 10.seconds.from_now
    )

    # 次のジョブがスケジュールされないことを確認
    PersistAnswers.stub :call, nil do
      assert_no_enqueued_jobs do
        PersistAnswersJob.perform_now(@question.id)
      end
    end
  end
end
