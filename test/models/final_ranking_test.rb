# frozen_string_literal: true

require "test_helper"

class FinalRankingTest < ActiveSupport::TestCase
  setup do
    @player = Player.create!(uuid: SecureRandom.uuid)
  end

  test "valid final ranking" do
    ranking = FinalRanking.new(
      player: @player,
      rank: 1,
      correct_count: 5,
      total_answered: 8,
      lottery_score: 0
    )
    assert ranking.valid?
  end

  test "requires player" do
    ranking = FinalRanking.new(rank: 1, correct_count: 5, total_answered: 8)
    assert_not ranking.valid?
    assert_includes ranking.errors[:player], "must exist"
  end

  test "requires rank" do
    ranking = FinalRanking.new(player: @player, correct_count: 5, total_answered: 8)
    assert_not ranking.valid?
    assert_includes ranking.errors[:rank], "can't be blank"
  end

  test "rank must be positive integer" do
    ranking = FinalRanking.new(player: @player, rank: 0, correct_count: 5, total_answered: 8)
    assert_not ranking.valid?
    assert_includes ranking.errors[:rank], "must be greater than 0"
  end

  test "correct_count must be non-negative" do
    ranking = FinalRanking.new(player: @player, rank: 1, correct_count: -1, total_answered: 8)
    assert_not ranking.valid?
    assert_includes ranking.errors[:correct_count], "must be greater than or equal to 0"
  end

  test "total_answered must be non-negative" do
    ranking = FinalRanking.new(player: @player, rank: 1, correct_count: 5, total_answered: -1)
    assert_not ranking.valid?
    assert_includes ranking.errors[:total_answered], "must be greater than or equal to 0"
  end

  test "lottery_score must be non-negative" do
    ranking = FinalRanking.new(player: @player, rank: 1, correct_count: 5, total_answered: 8, lottery_score: -1)
    assert_not ranking.valid?
    assert_includes ranking.errors[:lottery_score], "must be greater than or equal to 0"
  end

  test "ranked scope returns rankings in rank order" do
    player2 = Player.create!(uuid: SecureRandom.uuid)
    player3 = Player.create!(uuid: SecureRandom.uuid)

    ranking3 = FinalRanking.create!(player: player3, rank: 3, correct_count: 3, total_answered: 8)
    ranking1 = FinalRanking.create!(player: @player, rank: 1, correct_count: 5, total_answered: 8)
    ranking2 = FinalRanking.create!(player: player2, rank: 2, correct_count: 4, total_answered: 8)

    ranked = FinalRanking.ranked.to_a
    assert_equal [ ranking1, ranking2, ranking3 ], ranked
  end

  test "clear_all deletes all final rankings" do
    FinalRanking.create!(player: @player, rank: 1, correct_count: 5, total_answered: 8)
    assert_equal 1, FinalRanking.count

    FinalRanking.clear_all
    assert_equal 0, FinalRanking.count
  end

  test "to_ranking_entry converts to RankingEntry object" do
    ranking = FinalRanking.create!(
      player: @player,
      rank: 1,
      correct_count: 5,
      total_answered: 8,
      lottery_score: 2
    )

    entry = ranking.to_ranking_entry
    assert_instance_of RankingEntry, entry
    assert_equal @player.to_gid_param, entry.player_id
    assert_equal @player.name, entry.player_name
    assert_equal 1, entry.rank
    assert_equal 5, entry.correct_count
    assert_equal 8, entry.total_answered
    assert_equal 2, entry.lottery_score
  end
end
