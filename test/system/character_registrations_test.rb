require "application_system_test_case"

class CharacterRegistrationsTest < ApplicationSystemTestCase
  setup do
    @character_registration = character_registrations(:one)
  end

  test "visiting the index" do
    visit character_registrations_url
    assert_selector "h1", text: "Character registrations"
  end

  test "should create character registration" do
    visit character_registrations_url
    click_on "New character registration"

    click_on "Create Character registration"

    assert_text "Character registration was successfully created"
    click_on "Back"
  end

  test "should update Character registration" do
    visit character_registration_url(@character_registration)
    click_on "Edit this character registration", match: :first

    click_on "Update Character registration"

    assert_text "Character registration was successfully updated"
    click_on "Back"
  end

  test "should destroy Character registration" do
    visit character_registration_url(@character_registration)
    click_on "Destroy this character registration", match: :first

    assert_text "Character registration was successfully destroyed"
  end
end
