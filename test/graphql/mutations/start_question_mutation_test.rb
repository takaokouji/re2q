require "test_helper"
require "ostruct"
require "minitest/mock"

class Mutations::StartQuestionMutationTest < ActiveSupport::TestCase
  def setup
    @admin = create(:admin)
    @question = create(:question)

    state = CurrentQuizState.instance
    state.update!(quiz_active: true)
  end

  test "should start question for admin" do
    begin
      mutation = <<~GRAPHQL
        mutation StartQuestion($questionId: ID!) {
          startQuestion(input: { questionId: $questionId }) {
            currentQuizState {
              id
              quizActive
              questionActive
              question {
                id
                questionNumber
              }
            }
            errors
          }
        }
      GRAPHQL

      context = { current_admin: @admin }
      result = Re2qSchema.execute(mutation, variables: { questionId: @question.to_gid_param }, context: context)

      assert_empty result.dig("data", "startQuestion", "errors"), "GraphQL errors: #{result.dig("data", "startQuestion", "errors")&.join(", ")}"

      state = CurrentQuizState.instance
      state.reload

      assert_equal state.to_gid_param, result.dig("data", "startQuestion", "currentQuizState", "id")
      assert_equal state.quiz_active, result.dig("data", "startQuestion", "currentQuizState", "quizActive")
      assert_equal state.question_active?, result.dig("data", "startQuestion", "currentQuizState", "questionActive")
      assert_equal state.question.to_gid_param, result.dig("data", "startQuestion", "currentQuizState", "question", "id")
      assert_equal state.question.position, result.dig("data", "startQuestion", "currentQuizState", "question", "questionNumber")
    end
  end

  test "should not start question for non-admin" do
    mutation = <<~GRAPHQL
      mutation StartQuestion($questionId: ID!) {
        startQuestion(input: { questionId: $questionId }) {
          currentQuizState {
            id
          }
          errors
        }
      }
    GRAPHQL

    context = { current_admin: nil }
    result = Re2qSchema.execute(mutation, variables: { questionId: @question.to_gid_param }, context:)

    errors = result.dig("data", "startQuestion", "errors")
    assert_not_nil errors
    assert_equal "You must be an admin to perform this action", errors.first
    assert_equal CurrentQuizState.instance.to_gid_param, result.dig("data", "startQuestion", "currentQuizState", "id")
  end

  test "should return errors if QuizStateManager fails" do
    original_start_question = QuizStateManager.method(:start_question)
    QuizStateManager.define_singleton_method(:start_question) do |question_id|
      raise StandardError, "QuizStateManager error"
    end

    begin
      mutation = <<~GRAPHQL
        mutation StartQuestion($questionId: ID!) {
          startQuestion(input: { questionId: $questionId }) {
            currentQuizState {
              id
            }
            errors
          }
        }
      GRAPHQL

      context = { current_admin: @admin }
      result = Re2qSchema.execute(mutation, variables: { questionId: @question.to_gid.to_s }, context: context)

      assert_equal [ "QuizStateManager error" ], result.dig("data", "startQuestion", "errors")
      assert_not_nil result.dig("data", "startQuestion", "currentQuizState") # current_quiz_state is returned even on error
    ensure
      QuizStateManager.define_singleton_method(:start_question, original_start_question)
    end
  end
end
