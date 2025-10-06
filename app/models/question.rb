class Question < ApplicationRecord
  has_many :answers, dependent: :destroy

  validates :content, presence: true
  validates :correct_answer, inclusion: { in: [ true, false ] }
  validates :duration_seconds, numericality: { greater_than: 0 }
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
