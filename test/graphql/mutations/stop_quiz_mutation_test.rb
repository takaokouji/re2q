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

      assert_equal ["QuizStateManager error"], result.dig("data", "stopQuiz", "errors")
      assert_not_nil result.dig("data", "stopQuiz", "currentQuizState") # current_quiz_state is returned even on error
    ensure
      QuizStateManager.define_singleton_method(:stop_quiz, original_stop_quiz)
    end
  end
end
