require "test_helper"

class CharacterRegistrationVerificationControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get character_registration_verification_index_url
    assert_response :success
  end

  test "should get create" do
    get character_registration_verification_create_url
    assert_response :success
  end

  test "should get destroy" do
    get character_registration_verification_destroy_url
    assert_response :success
  end
end
