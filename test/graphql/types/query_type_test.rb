# frozen_string_literal: true

require "test_helper"

class Types::QueryTypeTest < ActiveSupport::TestCase
  test "ranking should return persisted final ranking when available" do
    # Create test data
    player1 = create(:player)
    player2 = create(:player)

    # Create persisted final ranking
    FinalRanking.create!(player: player1, rank: 1, correct_count: 5, total_answered: 8, lottery_score: 0)
    FinalRanking.create!(player: player2, rank: 2, correct_count: 3, total_answered: 8, lottery_score: 0)

    query = <<~GRAPHQL
      query {
        ranking {
          rank
          correctCount
          totalAnswered
          lotteryScore
        }
      }
    GRAPHQL

    result = Re2qSchema.execute(query)
    ranking = result.dig("data", "ranking")

    assert_equal 2, ranking.size
    assert_equal 1, ranking[0]["rank"]
    assert_equal 5, ranking[0]["correctCount"]
    assert_equal 2, ranking[1]["rank"]
    assert_equal 3, ranking[1]["correctCount"]
  end

  test "ranking should calculate ranking when no persisted ranking available" do
    # Create test data
    player1 = create(:player)
    player2 = create(:player)

    question1 = create(:question, correct_answer: true)
    question2 = create(:question, correct_answer: false)

    # Player 1: 2 correct answers
    create(:answer, player: player1, question: question1, player_answer: true)
    create(:answer, player: player1, question: question2, player_answer: false)

    # Player 2: 1 correct answer
    create(:answer, player: player2, question: question1, player_answer: true)
    create(:answer, player: player2, question: question2, player_answer: true)

    query = <<~GRAPHQL
      query {
        ranking {
          rank
          correctCount
          totalAnswered
        }
      }
    GRAPHQL

    result = Re2qSchema.execute(query)
    ranking = result.dig("data", "ranking")

    assert_equal 2, ranking.size
    # Player 1: rank 1, 2 correct
    assert_equal 1, ranking[0]["rank"]
    assert_equal 2, ranking[0]["correctCount"]
    # Player 2: rank 2, 1 correct
    assert_equal 2, ranking[1]["rank"]
    assert_equal 1, ranking[1]["correctCount"]
  end

  test "ranking with lottery should use persisted ranking when available" do
    player1 = create(:player)
    player2 = create(:player)

    # Create persisted final ranking with lottery scores
    FinalRanking.create!(player: player1, rank: 1, correct_count: 5, total_answered: 8, lottery_score: 1)
    FinalRanking.create!(player: player2, rank: 2, correct_count: 5, total_answered: 8, lottery_score: 2)

    query = <<~GRAPHQL
      query {
        ranking(lottery: true) {
          rank
          correctCount
          lotteryScore
        }
      }
    GRAPHQL

    result = Re2qSchema.execute(query)
    ranking = result.dig("data", "ranking")

    assert_equal 2, ranking.size
    assert_equal 1, ranking[0]["rank"]
    assert_equal 1, ranking[0]["lotteryScore"]
    assert_equal 2, ranking[1]["rank"]
    assert_equal 2, ranking[1]["lotteryScore"]
  end

  test "ranking should prefer persisted ranking over calculated ranking" do
    player = create(:player)
    question = create(:question, correct_answer: true)
    create(:answer, player: player, question: question, player_answer: true)

    # Create persisted ranking with different data
    FinalRanking.create!(player: player, rank: 1, correct_count: 10, total_answered: 10, lottery_score: 0)

    query = <<~GRAPHQL
      query {
        ranking {
          rank
          correctCount
          totalAnswered
        }
      }
    GRAPHQL

    result = Re2qSchema.execute(query)
    ranking = result.dig("data", "ranking")

    assert_equal 1, ranking.size
    # Should return persisted ranking (10 correct), not calculated (1 correct)
    assert_equal 1, ranking[0]["rank"]
    assert_equal 10, ranking[0]["correctCount"]
    assert_equal 10, ranking[0]["totalAnswered"]
  end
end
