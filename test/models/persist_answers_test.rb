# frozen_string_literal: true

require "test_helper"

class PersistAnswersTest < ActiveSupport::TestCase
  setup do
    @question = create(:question)
    @player1 = create(:player)
    @player2 = create(:player)
    Rails.cache.clear
  end

  test "persists cached answers to database" do
    # キャッシュに回答を保存
    cache_key1 = "answer:#{@question.id}:#{@player1.id}"
    cache_key2 = "answer:#{@question.id}:#{@player2.id}"

    Rails.cache.write(cache_key1, {
      player_id: @player1.id,
      question_id: @question.id,
      player_answer: true,
      answered_at: Time.current.iso8601
    })

    Rails.cache.write(cache_key2, {
      player_id: @player2.id,
      question_id: @question.id,
      player_answer: false,
      answered_at: Time.current.iso8601
    })

    # キーリストを保存
    Rails.cache.write("answer_keys:#{@question.id}", [ cache_key1, cache_key2 ])

    # PersistAnswers を実行
    PersistAnswers.call(question_id: @question.id)

    # DBに保存されていることを確認
    assert_equal 2, Answer.count
    assert Answer.exists?(player_id: @player1.id, question_id: @question.id, player_answer: true)
    assert Answer.exists?(player_id: @player2.id, question_id: @question.id, player_answer: false)
  end

  test "updates existing answer with last answer" do
    # 既存の回答をDBに保存
    existing_answer = create(:answer,
      player: @player1,
      question: @question,
      player_answer: true,
      answered_at: 5.seconds.ago
    )

    # キャッシュに新しい回答を保存（最後の回答）
    cache_key = "answer:#{@question.id}:#{@player1.id}"
    Rails.cache.write(cache_key, {
      player_id: @player1.id,
      question_id: @question.id,
      player_answer: false,  # 変更された回答
      answered_at: Time.current.iso8601
    })

    # キーリストを保存
    Rails.cache.write("answer_keys:#{@question.id}", [ cache_key ])

    # PersistAnswers を実行
    PersistAnswers.call(question_id: @question.id)

    # DBの回答が更新されていることを確認
    existing_answer.reload
    assert_equal false, existing_answer.player_answer
    assert_equal 1, Answer.count  # 回答は1つだけのまま
  end

  test "accepts multiple updates and keeps last answer" do
    # 1回目の回答をキャッシュに保存
    cache_key = "answer:#{@question.id}:#{@player1.id}"
    Rails.cache.write(cache_key, {
      player_id: @player1.id,
      question_id: @question.id,
      player_answer: true,
      answered_at: 3.seconds.ago.iso8601
    })
    Rails.cache.write("answer_keys:#{@question.id}", [ cache_key ])

    # 1回目の永続化
    PersistAnswers.call(question_id: @question.id)
    assert_equal true, Answer.find_by(player: @player1, question: @question).player_answer

    # 2回目の回答をキャッシュに保存
    Rails.cache.write(cache_key, {
      player_id: @player1.id,
      question_id: @question.id,
      player_answer: false,
      answered_at: 2.seconds.ago.iso8601
    })
    Rails.cache.write("answer_keys:#{@question.id}", [ cache_key ])

    # 2回目の永続化
    PersistAnswers.call(question_id: @question.id)
    assert_equal false, Answer.find_by(player: @player1, question: @question).player_answer

    # 3回目の回答をキャッシュに保存
    Rails.cache.write(cache_key, {
      player_id: @player1.id,
      question_id: @question.id,
      player_answer: true,
      answered_at: Time.current.iso8601
    })
    Rails.cache.write("answer_keys:#{@question.id}", [ cache_key ])

    # 3回目の永続化
    PersistAnswers.call(question_id: @question.id)

    # 最後の回答が保存されていることを確認
    final_answer = Answer.find_by(player: @player1, question: @question)
    assert_equal true, final_answer.player_answer
    assert_equal 1, Answer.count  # 回答は1つだけのまま
  end

  test "deletes cached answers after persistence" do
    # キャッシュに回答を保存
    cache_key = "answer:#{@question.id}:#{@player1.id}"
    Rails.cache.write(cache_key, {
      player_id: @player1.id,
      question_id: @question.id,
      player_answer: true,
      answered_at: Time.current.iso8601
    })

    key_list_key = "answer_keys:#{@question.id}"
    Rails.cache.write(key_list_key, [ cache_key ])

    # PersistAnswers を実行
    PersistAnswers.call(question_id: @question.id)

    # キャッシュが削除されていることを確認
    assert_nil Rails.cache.read(cache_key)
    assert_nil Rails.cache.read(key_list_key)
  end

  test "handles empty cache gracefully" do
    # 空のキャッシュで実行
    assert_nothing_raised do
      PersistAnswers.call(question_id: @question.id)
    end

    assert_equal 0, Answer.count
  end

  test "handles cache with nil answer_keys gracefully" do
    # answer_keys が nil の場合
    Rails.cache.write("answer_keys:#{@question.id}", nil)

    assert_nothing_raised do
      PersistAnswers.call(question_id: @question.id)
    end

    assert_equal 0, Answer.count
  end
end
