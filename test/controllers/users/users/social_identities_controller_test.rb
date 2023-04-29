require "test_helper"

class Users::Users::SocialIdentitiesControllerTest < ActionDispatch::IntegrationTest
  test "should get destroy" do
    get users_users_social_identities_destroy_url
    assert_response :success
  end
end
