require "test_helper"
require "ostruct"

class Mutations::SubmitAnswerMutationTest < ActiveSupport::TestCase
  def setup
    @player = create(:player)
    @question = create(:question)

    QuizStateManager.start_quiz
    QuizStateManager.start_question(@question.id)
  end

  test "should submit answer and store in cache" do
    begin
      mutation = <<~GRAPHQL
        mutation SubmitAnswer($answer: Boolean!) {
          submitAnswer(input: { answer: $answer }) {
            errors
          }
        }
      GRAPHQL

      context = { current_player: @player }
      result = Re2qSchema.execute(mutation, variables: { answer: true }, context: context)

      assert_empty result.dig("data", "submitAnswer", "errors")

      cache_key = "answer:#{@question.id}:#{@player.id}"
      key_list_key = "answer_keys:#{@question.id}"

      assert_not_nil Rails.cache.read(cache_key)
      assert_includes Rails.cache.read(key_list_key), cache_key
    end
  end

  test "should not submit answer without active player" do
    begin
      mutation = <<~GRAPHQL
        mutation SubmitAnswer($answer: Boolean!) {
          submitAnswer(input: { answer: $answer }) {
            errors
          }
        }
      GRAPHQL

      context = { current_player: nil }
      result = Re2qSchema.execute(mutation, variables: { answer: true }, context: context)

      errors = result.dig("data", "submitAnswer", "errors")
      assert_not_nil errors
      assert_equal "Player not found", errors.first
    end
  end

  test "should not submit answer without active question" do
    QuizStateManager.stop_question

    begin
      mutation = <<~GRAPHQL
        mutation SubmitAnswer($answer: Boolean!) {
          submitAnswer(input: { answer: $answer }) {
            errors
          }
        }
      GRAPHQL

      context = { current_player: @player }
      result = Re2qSchema.execute(mutation, variables: { answer: true }, context: context)

      errors = result.dig("data", "submitAnswer", "errors")
      assert_not_nil errors
      assert_equal "No active question", errors.first
    end
  end

  test "should return errors if Rails.cache.write fails" do
    original_cache_write = Rails.cache.method(:write)
    Rails.cache.define_singleton_method(:write) do |key, value, options|
      raise StandardError, "Cache write error"
    end

    begin
      mutation = <<~GRAPHQL
        mutation SubmitAnswer($answer: Boolean!) {
          submitAnswer(input: { answer: $answer }) {
            errors
          }
        }
      GRAPHQL

      context = { current_player: @player }
      result = Re2qSchema.execute(mutation, variables: { answer: true }, context: context)

      errors = result.dig("data", "submitAnswer", "errors")
      assert_not_nil errors
      assert_equal "Cache write error", errors.first
    ensure
      Rails.cache.define_singleton_method(:write, original_cache_write)
    end
  end
end
