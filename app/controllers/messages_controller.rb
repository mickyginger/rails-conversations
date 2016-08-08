class MessagesController < ApplicationController
  before_action do
    @conversation = Conversation.find(params[:conversation_id])
  end

  def index
    @conversation.messages.where("user_id != ? AND read = ?", current_user.id, false).update_all(read: true)
    @message = @conversation.messages.new
  end

  def create
    @message = @conversation.messages.new(message_params)
    @message.user = current_user

    if @message.save
      ActionCable.server.broadcast "messages", { conversation_id: @conversation.id }
      redirect_to conversation_messages_path(@conversation)
    end
  end

  private
    def message_params
      params.require(:message).permit(:body)
    end
end
