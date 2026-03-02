require "test_helper"

class ActionItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dossier = Dossier.create!(name: "Test Dossier")
    @action_item = @dossier.action_items.create!(description: "Test item", next_action: false)
  end

  test "toggle_next_action enables next_action" do
    patch toggle_next_action_action_item_path(@action_item), as: :turbo_stream
    assert_response :success

    @action_item.reload
    assert @action_item.next_action?
  end

  test "toggle_next_action disables next_action" do
    @action_item.update!(next_action: true)

    patch toggle_next_action_action_item_path(@action_item), as: :turbo_stream
    assert_response :success

    @action_item.reload
    assert_not @action_item.next_action?
  end

  test "toggle_next_action returns turbo stream with action_item replacement" do
    patch toggle_next_action_action_item_path(@action_item), as: :turbo_stream
    assert_response :success
    assert_match "turbo-stream", response.body
  end
end
