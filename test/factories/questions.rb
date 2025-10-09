FactoryBot.define do
  factory :question do
    sequence(:position) { |n| n }
    content { "Test Question" }
    correct_answer { true }
    duration_seconds { 10 }
  end
end
