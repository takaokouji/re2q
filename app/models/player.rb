class Player < ApplicationRecord
  has_many :answers, dependent: :destroy

  validates :uuid, presence: true, uniqueness: true

  HEX_TO_LABEL = {
    "0" => "い",
    "1" => "し",
    "2" => "か",
    "3" => "た",
    "4" => "う",
    "5" => "ん",
    "6" => "て",
    "7" => "と",
    "8" => "の",
    "9" => "つ",
    "a" => "は",
    "b" => "こ",
    "c" => "に",
    "d" => "な",
    "e" => "く",
    "f" => "き"
  }

  def name
    return nil if uuid.blank?

    @name ||= uuid[0...6].downcase.gsub(/./) { HEX_TO_LABEL[it] }
  end
end
