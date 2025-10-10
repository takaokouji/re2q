# frozen_string_literal: true

class FinalRanking < ApplicationRecord
  belongs_to :player

  validates :rank, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :correct_count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_answered, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :lottery_score, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # ランキング順にソート（rank昇順）
  scope :ranked, -> { order(:rank) }

  # ランキングをすべて削除
  def self.clear_all
    delete_all
  end

  # RankingEntryオブジェクトに変換
  def to_ranking_entry
    RankingEntry.new(
      player_id: player.to_gid_param,
      player_name: player.name,
      rank: rank,
      correct_count: correct_count,
      total_answered: total_answered,
      lottery_score: lottery_score
    )
  end
end
