require "test_helper"
require "ostruct"
require "minitest/mock"

class Mutations::StartNextQuestionMutationTest < ActiveSupport::TestCase
  def setup
    @admin = create(:admin)
    @question1 = create(:question, position: 1)
    @question2 = create(:question, position: 2)
    @question3 = create(:question, position: 3)

    state = CurrentQuizState.instance
    state.update!(quiz_active: true)
  end

  test "should start next question for admin when not at last question" do
    # 最初の問題を開始
    QuizStateManager.start_question(@question1.id)
    # 問題が終わるまで待つ
    sleep 0.1
    QuizStateManager.stop_question

    mutation = <<~GRAPHQL
      mutation StartNextQuestion {
        startNextQuestion(input: {}) {
          currentQuizState {
            id
            quizActive
            questionActive
            question {
              id
              questionNumber
            }
          }
          isLastQuestion
          errors
        }
      }
    GRAPHQL

    context = { current_admin: @admin }
    result = Re2qSchema.execute(mutation, variables: {}, context: context)

    assert_empty result.dig("data", "startNextQuestion", "errors"), "GraphQL errors: #{result.dig("data", "startNextQuestion", "errors")&.join(", ")}"

    state = CurrentQuizState.instance
    state.reload

    assert_equal state.to_gid_param, result.dig("data", "startNextQuestion", "currentQuizState", "id")
    assert_equal state.quiz_active, result.dig("data", "startNextQuestion", "currentQuizState", "quizActive")
    assert_equal state.question_active?, result.dig("data", "startNextQuestion", "currentQuizState", "questionActive")
    assert_equal @question2.to_gid_param, result.dig("data", "startNextQuestion", "currentQuizState", "question", "id")
    assert_equal @question2.position, result.dig("data", "startNextQuestion", "currentQuizState", "question", "questionNumber")
    assert_equal false, result.dig("data", "startNextQuestion", "isLastQuestion")
  end

  test "should start last question and set isLastQuestion to true" do
    # 2番目の問題を開始
    QuizStateManager.start_question(@question2.id)
    sleep 0.1
    QuizStateManager.stop_question

    mutation = <<~GRAPHQL
      mutation StartNextQuestion {
        startNextQuestion(input: {}) {
          currentQuizState {
            id
            question {
              id
              questionNumber
            }
          }
          isLastQuestion
          errors
        }
      }
    GRAPHQL

    context = { current_admin: @admin }
    result = Re2qSchema.execute(mutation, variables: {}, context: context)

    assert_empty result.dig("data", "startNextQuestion", "errors")
    assert_equal @question3.to_gid_param, result.dig("data", "startNextQuestion", "currentQuizState", "question", "id")
    assert_equal true, result.dig("data", "startNextQuestion", "isLastQuestion")
  end

  test "should start first question when no current question" do
    mutation = <<~GRAPHQL
      mutation StartNextQuestion {
        startNextQuestion(input: {}) {
          currentQuizState {
            id
            question {
              id
              questionNumber
            }
          }
          isLastQuestion
          errors
        }
      }
    GRAPHQL

    context = { current_admin: @admin }
    result = Re2qSchema.execute(mutation, variables: {}, context: context)

    assert_empty result.dig("data", "startNextQuestion", "errors")
    assert_equal @question1.to_gid_param, result.dig("data", "startNextQuestion", "currentQuizState", "question", "id")
    assert_equal false, result.dig("data", "startNextQuestion", "isLastQuestion")
  end

  test "should not start next question for non-admin" do
    mutation = <<~GRAPHQL
      mutation StartNextQuestion {
        startNextQuestion(input: {}) {
          currentQuizState {
            id
          }
          isLastQuestion
          errors
        }
      }
    GRAPHQL

    context = { current_admin: nil }
    result = Re2qSchema.execute(mutation, variables: {}, context:)

    errors = result.dig("data", "startNextQuestion", "errors")
    assert_not_nil errors
    assert_equal "管理者認証が必要です", errors.first
    assert_equal CurrentQuizState.instance.to_gid_param, result.dig("data", "startNextQuestion", "currentQuizState", "id")
    assert_equal false, result.dig("data", "startNextQuestion", "isLastQuestion")
  end

  test "should return errors when no questions available" do
    # すべての問題を削除
    Question.destroy_all

    mutation = <<~GRAPHQL
      mutation StartNextQuestion {
        startNextQuestion(input: {}) {
          currentQuizState {
            id
          }
          isLastQuestion
          errors
        }
      }
    GRAPHQL

    context = { current_admin: @admin }
    result = Re2qSchema.execute(mutation, variables: {}, context: context)

    errors = result.dig("data", "startNextQuestion", "errors")
    assert_not_nil errors
    assert_equal "No questions available", errors.first
  end

  test "should return errors when no more questions available" do
    # 最後の問題を開始
    QuizStateManager.start_question(@question3.id)
    sleep 0.1
    QuizStateManager.stop_question

    mutation = <<~GRAPHQL
      mutation StartNextQuestion {
        startNextQuestion(input: {}) {
          currentQuizState {
            id
          }
          isLastQuestion
          errors
        }
      }
    GRAPHQL

    context = { current_admin: @admin }
    result = Re2qSchema.execute(mutation, variables: {}, context: context)

    errors = result.dig("data", "startNextQuestion", "errors")
    assert_not_nil errors
    assert_equal "No more questions available", errors.first
  end

  test "should return errors if QuizStateManager fails" do
    original_start_question = QuizStateManager.method(:start_question)
    QuizStateManager.define_singleton_method(:start_question) do |question_id|
      raise StandardError, "QuizStateManager error"
    end

    begin
      mutation = <<~GRAPHQL
        mutation StartNextQuestion {
          startNextQuestion(input: {}) {
            currentQuizState {
              id
            }
            isLastQuestion
            errors
          }
        }
      GRAPHQL

      context = { current_admin: @admin }
      result = Re2qSchema.execute(mutation, variables: {}, context: context)

      assert_equal [ "QuizStateManager error" ], result.dig("data", "startNextQuestion", "errors")
      assert_not_nil result.dig("data", "startNextQuestion", "currentQuizState")
      assert_equal false, result.dig("data", "startNextQuestion", "isLastQuestion")
    ensure
      QuizStateManager.define_singleton_method(:start_question, original_start_question)
    end
  end
end
