require "test_helper"

class Mutations::ExecuteLotteryMutationTest < ActiveSupport::TestCase
  def setup
    @admin = create(:admin)
    @player1 = create(:player)
    @player2 = create(:player)
    @player3 = create(:player)

    # Create questions
    @question1 = create(:question, correct_answer: true, duration_seconds: 10)
    @question2 = create(:question, correct_answer: false, duration_seconds: 10)

    # Player 1: 2 correct answers
    create(:answer, player: @player1, question: @question1, player_answer: true)
    create(:answer, player: @player1, question: @question2, player_answer: false)

    # Player 2: 1 correct answer
    create(:answer, player: @player2, question: @question1, player_answer: true)
    create(:answer, player: @player2, question: @question2, player_answer: true)

    # Player 3: 2 correct answers (tied with Player 1)
    create(:answer, player: @player3, question: @question1, player_answer: true)
    create(:answer, player: @player3, question: @question2, player_answer: false)
  end

  test "should execute lottery and return updated ranking for admin" do
    mutation = <<~GRAPHQL
      mutation {
        executeLottery(input: {}) {
          rankingEntries {
            playerId
            playerName
            correctCount
            totalAnswered
            rank
            lotteryScore
          }
          errors
        }
      }
    GRAPHQL

    context = { current_admin: @admin }
    result = Re2qSchema.execute(mutation, context: context)

    assert_empty result.dig("data", "executeLottery", "errors"), "GraphQL errors: #{result.dig("data", "executeLottery", "errors")&.join(", ")}"
    ranking_entries = result.dig("data", "executeLottery", "rankingEntries")
    assert_not_empty ranking_entries

    # Verify that lottery_score is applied and ranks are adjusted
    # Player 1 and Player 3 are tied with 2 correct answers.
    # One of them should have lottery_score: 1 and the other 0.
    player1_entry = ranking_entries.find { |entry| entry["playerId"] == @player1.to_gid_param }
    player3_entry = ranking_entries.find { |entry| entry["playerId"] == @player3.to_gid_param }

    assert_not_nil player1_entry
    assert_not_nil player3_entry

    assert_equal 2, player1_entry["correctCount"]
    assert_equal 2, player3_entry["correctCount"]

    # Check that one of them has lottery_score 1 and the other 0
    assert_equal 1, [ player1_entry["lotteryScore"], player3_entry["lotteryScore"] ].sum
    assert_includes [ 0, 1 ], player1_entry["lotteryScore"]
    assert_includes [ 0, 1 ], player3_entry["lotteryScore"]

    # Verify ranks are different for tied players after lottery
    assert_not_equal player1_entry["rank"], player3_entry["rank"]

    # Verify player 2's rank
    player2_entry = ranking_entries.find { |entry| entry["playerId"] == @player2.to_gid_param }
    assert_equal 1, player2_entry["correctCount"]
    assert_equal 3, player2_entry["rank"]
  end

  test "should not execute lottery for non-admin" do
    mutation = <<~GRAPHQL
      mutation {
        executeLottery(input: {}) {
          rankingEntries {
            playerId
          }
          errors
        }
      }
    GRAPHQL

    context = { current_admin: nil }
    result = Re2qSchema.execute(mutation, context: context)

    assert_equal "管理者認証が必要です", result["errors"].first["message"]
    assert_nil result.dig("data", "executeLottery", "rankingEntries")
  end
end
