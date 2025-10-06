class Answer < ApplicationRecord
  belongs_to :player
  belongs_to :question

  validates :player_answer, inclusion: { in: [ true, false ] }
  validates :player_id, uniqueness: { scope: :question_id }
end
