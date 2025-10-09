require "test_helper"
require "ostruct"
require "base64"

class Mutations::AdminLoginMutationTest < ActiveSupport::TestCase
  def setup
    @admin = create(:admin, username: "testadmin", password: "password")
  end

  test "should login admin with correct credentials" do
    mutation = <<~GRAPHQL
      mutation AdminLogin($username: String!, $password: String!) {
        adminLogin(input: { username: $username, password: $password }) {
          admin {
            id
            username
          }
          errors
        }
      }
    GRAPHQL

    context = { controller: OpenStruct.new(session: {}) }
    result = Re2qSchema.execute(mutation, variables: { username: "testadmin", password: "password" }, context: context)

    assert_empty result.dig("data", "adminLogin", "errors")
    assert_equal @admin.to_gid.to_s, Base64.decode64(result.dig("data", "adminLogin", "admin", "id"))
    assert_equal @admin.username, result.dig("data", "adminLogin", "admin", "username")
    assert_equal @admin.id, context[:controller].session[:admin_id]
  end

  test "should not login admin with incorrect username" do
    mutation = <<~GRAPHQL
      mutation AdminLogin($username: String!, $password: String!) {
        adminLogin(input: { username: $username, password: $password }) {
          admin {
            id
          }
          errors
        }
      }
    GRAPHQL

    context = { controller: OpenStruct.new(session: {}) }
    result = Re2qSchema.execute(mutation, variables: { username: "wrongadmin", password: "password" }, context: context)

    assert_equal [ "ユーザー名またはパスワードが正しくありません" ], result.dig("data", "adminLogin", "errors")
    assert_nil result.dig("data", "adminLogin", "admin")
    assert_nil context[:controller].session[:admin_id]
  end

  test "should not login admin with incorrect password" do
    mutation = <<~GRAPHQL
      mutation AdminLogin($username: String!, $password: String!) {
        adminLogin(input: { username: $username, password: $password }) {
          admin {
            id
          }
          errors
        }
      }
    GRAPHQL

    context = { controller: OpenStruct.new(session: {}) }
    result = Re2qSchema.execute(mutation, variables: { username: "testadmin", password: "wrongpassword" }, context: context)

    assert_equal [ "ユーザー名またはパスワードが正しくありません" ], result.dig("data", "adminLogin", "errors")
    assert_nil result.dig("data", "adminLogin", "admin")
    assert_nil context[:controller].session[:admin_id]
  end
end
