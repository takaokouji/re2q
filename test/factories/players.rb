FactoryBot.define do
  factory :player do
    sequence(:uuid) { |n| "player-uuid-#{n}" }
  end
end
