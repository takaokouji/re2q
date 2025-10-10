require "test_helper"
require "ostruct"

class Mutations::StopQuizMutationTest < ActiveSupport::TestCase
  def setup
    @admin = create(:admin)
    @question = create(:question)

    QuizStateManager.start_quiz
  end

  test "should stop quiz for admin" do
    mutation = <<~GRAPHQL
      mutation {
        stopQuiz(input: {}) {
          currentQuizState {
            id
            quizActive
            questionActive
          }
          errors
        }
      }
    GRAPHQL

    context = { current_admin: @admin }
    result = Re2qSchema.execute(mutation, context: context)

    state = CurrentQuizState.instance

    assert_empty result.dig("data", "stopQuiz", "errors")
    assert_equal state.to_gid_param, result.dig("data", "stopQuiz", "currentQuizState", "id")
    assert_equal state.quiz_active?, result.dig("data", "stopQuiz", "currentQuizState", "quizActive")
    assert_equal state.question_active?, result.dig("data", "stopQuiz", "currentQuizState", "questionActive")
  end

  test "should not stop quiz for non-admin" do
    mutation = <<~GRAPHQL
      mutation {
        stopQuiz(input: {}) {
          currentQuizState {
            id
          }
          errors
        }
      }
    GRAPHQL

    context = { current_admin: nil }
    result = Re2qSchema.execute(mutation, context: context)

    errors = result.dig("data", "stopQuiz", "errors")
    assert_not_nil errors
    assert_equal "管理者認証が必要です", errors.first
  end

  test "should return errors if QuizStateManager fails" do
    original_stop_quiz = QuizStateManager.method(:stop_quiz)
    QuizStateManager.define_singleton_method(:stop_quiz) do
      raise StandardError, "QuizStateManager error"
    end

    begin
      mutation = <<~GRAPHQL
        mutation {
          stopQuiz(input: {}) {
            currentQuizState {
              id
            }
            errors
          }
        }
      GRAPHQL

      context = { current_admin: @admin }
      result = Re2qSchema.execute(mutation, context: context)

      assert_equal [ "QuizStateManager error" ], result.dig("data", "stopQuiz", "errors")
      assert_not_nil result.dig("data", "stopQuiz", "currentQuizState") # current_quiz_state is returned even on error
    ensure
      QuizStateManager.define_singleton_method(:stop_quiz, original_stop_quiz)
    end
  end

  test "should persist final ranking when quiz is stopped" do
    # Create test data: 3 players with answers
    player1 = create(:player)
    player2 = create(:player)
    player3 = create(:player)

    question1 = create(:question, correct_answer: true)
    question2 = create(:question, correct_answer: false)

    # Player 1: 2 correct answers
    create(:answer, player: player1, question: question1, player_answer: true)
    create(:answer, player: player1, question: question2, player_answer: false)

    # Player 2: 1 correct answer
    create(:answer, player: player2, question: question1, player_answer: true)
    create(:answer, player: player2, question: question2, player_answer: true)

    # Player 3: 1 correct answer
    create(:answer, player: player3, question: question1, player_answer: true)
    create(:answer, player: player3, question: question2, player_answer: true)

    mutation = <<~GRAPHQL
      mutation {
        stopQuiz(input: {}) {
          currentQuizState {
            id
          }
          errors
        }
      }
    GRAPHQL

    context = { current_admin: @admin }

    assert_equal 0, FinalRanking.count

    result = Re2qSchema.execute(mutation, context: context)

    assert_empty result.dig("data", "stopQuiz", "errors")

    # FinalRanking が作成されていることを確認
    assert_equal 3, FinalRanking.count

    # ランキング順に取得して確認
    rankings = FinalRanking.ranked.to_a

    # Player 1: rank 1, 2 correct
    assert_equal player1.id, rankings[0].player_id
    assert_equal 1, rankings[0].rank
    assert_equal 2, rankings[0].correct_count

    # Player 2 and 3: 1 correct each
    # lottery により lottery_score が割り振られるため、順位は 2 と 3 になる
    assert_equal 1, rankings[1].correct_count
    assert_equal 2, rankings[1].rank
    assert_equal 1, rankings[2].correct_count
    assert_equal 3, rankings[2].rank

    # lottery_score は 1 と 2 になる（順不同）
    lottery_scores = [ rankings[1].lottery_score, rankings[2].lottery_score ].sort
    assert_equal [ 1, 2 ], lottery_scores
  end

  test "should clear previous final ranking before persisting new one" do
    # Create existing final ranking
    old_player = create(:player)
    FinalRanking.create!(player: old_player, rank: 1, correct_count: 10, total_answered: 10)

    assert_equal 1, FinalRanking.count

    # Create new test data
    new_player = create(:player)
    question = create(:question, correct_answer: true)
    create(:answer, player: new_player, question: question, player_answer: true)

    mutation = <<~GRAPHQL
      mutation {
        stopQuiz(input: {}) {
          currentQuizState {
            id
          }
          errors
        }
      }
    GRAPHQL

    context = { current_admin: @admin }
    result = Re2qSchema.execute(mutation, context: context)

    assert_empty result.dig("data", "stopQuiz", "errors")

    # 古いランキングは削除され、新しいランキングのみが残る
    assert_equal 1, FinalRanking.count
    final_ranking = FinalRanking.first
    assert_equal new_player.id, final_ranking.player_id
  end
end
