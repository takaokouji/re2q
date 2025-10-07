class CurrentQuizState < ApplicationRecord
  belongs_to :question, optional: true

  validates :duration_seconds, numericality: { greater_than: 0 }, allow_nil: true
  validate :singleton_record

  def self.instance
    first_or_create!
  end

  def question_active?
    return false unless quiz_active? && question_id.present?
    return false unless question_started_at && question_ends_at

    Time.current.between?(question_started_at, question_ends_at)
  end

  def accepting_answers?
    question_active?
  end

  # 残り時間（秒）
  def remaining_seconds
    return 0 unless question_active?
    [ (question_ends_at - Time.current).to_i, 0 ].max
  end

  private

  def singleton_record
    if persisted? && self.class.where.not(id: id).exists?
      errors.add(:base, "Only one CurrentQuizState record is allowed")
    end
  end
end
