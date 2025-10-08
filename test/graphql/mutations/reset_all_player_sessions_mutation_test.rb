require "test_helper"

class Mutations::ResetAllPlayerSessionsMutationTest < ActiveSupport::TestCase
  test "should delete all players" do
    create_list(:player, 2)

    assert_equal 2, Player.count

    mutation = <<~GRAPHQL
      mutation {
        resetAllPlayerSessions(input: {}) {
          success
          errors
        }
      }
    GRAPHQL

    admin = create(:admin)
    context = { current_admin: admin }

    result = Re2qSchema.execute(mutation, context: context)

    assert_equal 0, Player.count
    assert_equal true, result.dig("data", "resetAllPlayerSessions", "success")
    assert_empty result.dig("data", "resetAllPlayerSessions", "errors")
  end
end
