class Player < ApplicationRecord
  has_many :answers, dependent: :destroy

  validates :uuid, presence: true, uniqueness: true
end
