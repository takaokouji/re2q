require "test_helper"

class Mutations::ResetQuizMutationTest < ActiveSupport::TestCase
  def setup
    @admin = create(:admin)
    @question = create(:question)
  end

  test "should reset quiz state and delete all players and answers for admin" do
    # Setup: create quiz state with active question
    QuizStateManager.start_quiz
    QuizStateManager.start_question(@question.id)

    # Create some players and answers
    player1 = create(:player)
    player2 = create(:player)
    create(:answer, player: player1, question: @question, player_answer: true)
    create(:answer, player: player2, question: @question, player_answer: false)

    assert_equal 2, Player.count
    assert_equal 2, Answer.count

    state = CurrentQuizState.instance
    assert state.quiz_active?
    assert_not_nil state.question_id

    mutation = <<~GRAPHQL
      mutation {
        resetQuiz(input: {}) {
          success
          deletedAnswersCount
          deletedPlayersCount
          errors
        }
      }
    GRAPHQL

    context = { current_admin: @admin }
    result = Re2qSchema.execute(mutation, context: context)

    # Verify response
    assert_equal true, result.dig("data", "resetQuiz", "success")
    assert_equal 2, result.dig("data", "resetQuiz", "deletedAnswersCount")
    assert_equal 2, result.dig("data", "resetQuiz", "deletedPlayersCount")
    assert_empty result.dig("data", "resetQuiz", "errors")

    # Verify database state
    assert_equal 0, Player.count
    assert_equal 0, Answer.count

    # Verify quiz state is reset
    state.reload
    assert_not state.quiz_active?
    assert_nil state.question_id
    assert_nil state.question_started_at
    assert_nil state.question_ends_at
    assert_nil state.duration_seconds
  end

  test "should not reset quiz for non-admin" do
    mutation = <<~GRAPHQL
      mutation {
        resetQuiz(input: {}) {
          success
          errors
        }
      }
    GRAPHQL

    context = { current_admin: nil }
    result = Re2qSchema.execute(mutation, context: context)

    errors = result.dig("data", "resetQuiz", "errors")
    assert_not_nil errors
    assert_equal "管理者認証が必要です", errors.first
    assert_equal false, result.dig("data", "resetQuiz", "success")
  end

  test "should delete final rankings when quiz is reset" do
    # Create final rankings
    player1 = create(:player)
    player2 = create(:player)
    FinalRanking.create!(player: player1, rank: 1, correct_count: 5, total_answered: 8, lottery_score: 0)
    FinalRanking.create!(player: player2, rank: 2, correct_count: 3, total_answered: 8, lottery_score: 0)

    assert_equal 2, FinalRanking.count

    mutation = <<~GRAPHQL
      mutation {
        resetQuiz(input: {}) {
          success
          deletedAnswersCount
          deletedPlayersCount
          errors
        }
      }
    GRAPHQL

    context = { current_admin: @admin }
    result = Re2qSchema.execute(mutation, context: context)

    assert_equal true, result.dig("data", "resetQuiz", "success")
    assert_empty result.dig("data", "resetQuiz", "errors")

    # FinalRanking が削除されていることを確認
    assert_equal 0, FinalRanking.count
  end
end
