class MeetingActionItemsController < ApplicationController
  before_action :set_meeting

  def create
    @action_item = @meeting.action_items.build(action_item_params)

    if @action_item.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @meeting }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("meeting_action_item_form", partial: "meetings/action_item_form", locals: { meeting: @meeting, action_item: @action_item }) }
        format.html { redirect_to @meeting, alert: @action_item.errors.full_messages.join(", ") }
      end
    end
  end

  private

  def set_meeting
    @meeting = Meeting.find(params[:meeting_id])
  end

  def action_item_params
    params.require(:action_item).permit(:description)
  end
end
