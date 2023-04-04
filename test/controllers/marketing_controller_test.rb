require "test_helper"

class MarketingControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get marketing_index_url
    assert_response :success
  end
end
