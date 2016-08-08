require 'test_helper'

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get conversations_index_url
    assert_response :success
  end

end
