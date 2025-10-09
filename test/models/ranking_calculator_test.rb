require "test_helper"

class RankingCalculatorTest < ActiveSupport::TestCase
  def setup
    @player1 = create(:player)
    @player2 = create(:player)
    @player3 = create(:player)
    @player4 = create(:player)

    # Create questions
    @question1 = create(:question, position: 1, correct_answer: true, duration_seconds: 10)
    @question2 = create(:question, position: 2, correct_answer: false, duration_seconds: 10)
    @question3 = create(:question, position: 3, correct_answer: true, duration_seconds: 10)

    # Player 1: 2 correct answers (Q1, Q3) - total 3 answered
    create(:answer, player: @player1, question: @question1, player_answer: true)
    create(:answer, player: @player1, question: @question2, player_answer: true)
    create(:answer, player: @player1, question: @question3, player_answer: true)

    # Player 2: 1 correct answer (Q1) - total 2 answered
    create(:answer, player: @player2, question: @question1, player_answer: true)
    create(:answer, player: @player2, question: @question2, player_answer: true)

    # Player 3: 2 correct answers (Q1, Q3) - total 3 answered (tied with Player 1)
    create(:answer, player: @player3, question: @question1, player_answer: true)
    create(:answer, player: @player3, question: @question2, player_answer: true)
    create(:answer, player: @player3, question: @question3, player_answer: true)

    # Player 4: 0 correct answers - total 1 answered
    create(:answer, player: @player4, question: @question1, player_answer: false)
  end

  test "calculate should return correct ranking without lottery" do
    ranking = RankingCalculator.calculate

    # Expected ranks:
    # Player 1: 2 correct, 3 answered -> Rank 1 (tied with Player 3)
    # Player 3: 2 correct, 3 answered -> Rank 1 (tied with Player 1)
    # Player 2: 1 correct, 2 answered -> Rank 3
    # Player 4: 0 correct, 1 answered -> Rank 4

    player1_entry = ranking.find { |entry| entry.player_id == @player1.to_gid_param }
    player2_entry = ranking.find { |entry| entry.player_id == @player2.to_gid_param }
    player3_entry = ranking.find { |entry| entry.player_id == @player3.to_gid_param }
    player4_entry = ranking.find { |entry| entry.player_id == @player4.to_gid_param }

    assert_equal 2, player1_entry.correct_count
    assert_equal 3, player1_entry.total_answered
    assert_equal 1, player1_entry.rank
    assert_equal 0, player1_entry.lottery_score # Should be 0 as no lottery applied

    assert_equal 1, player2_entry.correct_count
    assert_equal 2, player2_entry.total_answered
    assert_equal 3, player2_entry.rank
    assert_equal 0, player2_entry.lottery_score

    assert_equal 2, player3_entry.correct_count
    assert_equal 3, player3_entry.total_answered
    assert_equal 1, player3_entry.rank
    assert_equal 0, player3_entry.lottery_score

    assert_equal 0, player4_entry.correct_count
    assert_equal 1, player4_entry.total_answered
    assert_equal 4, player4_entry.rank
    assert_equal 0, player4_entry.lottery_score

    # Verify that Player 1 and Player 3 have the same rank
    assert_equal player1_entry.rank, player3_entry.rank
  end

  test "calculate_with_lottery should return correct ranking with lottery" do
    ranking = RankingCalculator.calculate(lottery: true)

    # Expected ranks after lottery:
    # Player 1 or Player 3 will be Rank 1, the other Rank 2
    # Player 2: Rank 3
    # Player 4: Rank 4

    player1_entry = ranking.find { |entry| entry.player_id == @player1.to_gid_param }
    player2_entry = ranking.find { |entry| entry.player_id == @player2.to_gid_param }
    player3_entry = ranking.find { |entry| entry.player_id == @player3.to_gid_param }
    player4_entry = ranking.find { |entry| entry.player_id == @player4.to_gid_param }

    assert_equal 2, player1_entry.correct_count
    assert_equal 3, player1_entry.total_answered
    assert_includes [ 1, 2 ], player1_entry.rank
    assert_includes [ 0, 1, 2 ], player1_entry.lottery_score

    assert_equal 1, player2_entry.correct_count
    assert_equal 2, player2_entry.total_answered
    assert_equal 3, player2_entry.rank
    assert_equal 0, player2_entry.lottery_score

    assert_equal 2, player3_entry.correct_count
    assert_equal 3, player3_entry.total_answered
    assert_includes [ 1, 2 ], player3_entry.rank
    assert_includes [ 0, 1, 2 ], player3_entry.lottery_score

    assert_equal 0, player4_entry.correct_count
    assert_equal 1, player4_entry.total_answered
    assert_equal 4, player4_entry.rank
    assert_equal 0, player4_entry.lottery_score

    # Verify that Player 1 and Player 3 have different ranks after lottery
    assert_not_equal player1_entry.rank, player3_entry.rank

    # Verify that one of Player 1 or Player 3 has lottery_score 1, and the other 2
    assert_equal 3, [ player1_entry.lottery_score, player3_entry.lottery_score ].sum
  end
end
