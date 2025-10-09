FactoryBot.define do
  factory :answer do
    association :player
    association :question
    player_answer { [true, false].sample }
    answered_at { Time.current }
  end
end