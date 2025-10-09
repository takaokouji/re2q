require "test_helper"
require "ostruct"

class Mutations::AdminLogoutMutationTest < ActiveSupport::TestCase
  def setup
    @admin = create(:admin)
  end

  test "should logout admin" do
    mutation = <<~GRAPHQL
      mutation {
        adminLogout(input: {}) {
          success
        }
      }
    GRAPHQL

    context = { controller: OpenStruct.new(session: { admin_id: @admin.id }) }
    result = Re2qSchema.execute(mutation, context: context)

    assert_equal true, result.dig("data", "adminLogout", "success")
    assert_nil context[:controller].session[:admin_id]
  end
end
