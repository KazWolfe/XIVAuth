require "test_helper"

class CharacterRegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @character_registration = character_registrations(:one)
  end

  test "should get index" do
    get character_registrations_url
    assert_response :success
  end

  test "should get new" do
    get new_character_registration_url
    assert_response :success
  end

  test "should create character_registration" do
    assert_difference("CharacterRegistration.count") do
      post character_registrations_url, params: { character_registration: {  } }
    end

    assert_redirected_to character_registration_url(CharacterRegistration.last)
  end

  test "should show character_registration" do
    get character_registration_url(@character_registration)
    assert_response :success
  end

  test "should get edit" do
    get edit_character_registration_url(@character_registration)
    assert_response :success
  end

  test "should update character_registration" do
    patch character_registration_url(@character_registration), params: { character_registration: {  } }
    assert_redirected_to character_registration_url(@character_registration)
  end

  test "should destroy character_registration" do
    assert_difference("CharacterRegistration.count", -1) do
      delete character_registration_url(@character_registration)
    end

    assert_redirected_to character_registrations_url
  end
end
