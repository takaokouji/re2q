require "test_helper"
require "ostruct"

class Mutations::StartQuizMutationTest < ActiveSupport::TestCase
  def setup
    @admin = create(:admin)
  end

  test "should start quiz for admin" do
    begin
      mutation = <<~GRAPHQL
        mutation {
          startQuiz(input: {}) {
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

      assert_empty result.dig("data", "startQuiz", "errors")
      assert_equal state.to_gid_param, result.dig("data", "startQuiz", "currentQuizState", "id")
      assert_equal state.quiz_active?, result.dig("data", "startQuiz", "currentQuizState", "quizActive")
      assert_equal state.question_active?, result.dig("data", "startQuiz", "currentQuizState", "questionActive")
    end
  end

  test "should not start quiz for non-admin" do
    mutation = <<~GRAPHQL
      mutation {
        startQuiz(input: {}) {
          currentQuizState {
            id
          }
          errors
        }
      }
    GRAPHQL

    context = { current_admin: nil }
    result = Re2qSchema.execute(mutation, context: context)

    errors = result.dig("data", "startQuiz", "errors")
    assert_not_nil errors
    assert_equal "You must be an admin to perform this action", errors.first
  end

  test "should return errors if QuizStateManager fails" do
    original_start_quiz = QuizStateManager.method(:start_quiz)
    QuizStateManager.define_singleton_method(:start_quiz) do
      raise StandardError, "QuizStateManager error"
    end

    begin
      mutation = <<~GRAPHQL
        mutation {
          startQuiz(input: {}) {
            currentQuizState {
              id
            }
            errors
          }
        }
      GRAPHQL

      context = { current_admin: @admin }
      result = Re2qSchema.execute(mutation, context: context)

      assert_equal ["QuizStateManager error"], result.dig("data", "startQuiz", "errors")
      assert_not_nil result.dig("data", "startQuiz", "currentQuizState") # current_quiz_state is returned even on error
    ensure
      QuizStateManager.define_singleton_method(:start_quiz, original_start_quiz)
    end
  end
end
