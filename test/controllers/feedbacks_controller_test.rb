require "test_helper"

class FeedbacksControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_feedback_url
    assert_response :success
    assert_select "h1", "Send feedback"
  end

  test "should create feedback" do
    assert_difference("Feedback.count") do
      post feedback_url, params: { feedback: { message: "Great charts, please add basis metrics." } }
    end

    assert_redirected_to root_url
    assert_equal "Thank you for your feedback!", flash[:notice]
  end

  test "should associate feedback with logged in user" do
    user = users(:one)
    post session_url, params: { session: { email: user.email, password: "password123" } }

    assert_difference("Feedback.count") do
      post feedback_url, params: { feedback: { message: "Signed-in feedback." } }
    end

    assert_equal user.id, Feedback.last.user_id
  end

  test "should render errors for blank message" do
    assert_no_difference("Feedback.count") do
      post feedback_url, params: { feedback: { message: "" } }
    end

    assert_response :unprocessable_entity
    assert_select ".text-red-800"
  end
end
