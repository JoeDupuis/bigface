class InvitesController < ApplicationController
  before_action :set_invite, only: [ :show, :update, :destroy ]

  def index
    @invites = Invite.pending_for(current_user)
  end

  def show
  end

  def new
    @invite = Invite.new
  end

  def create
    @invite = Current.session.user.sent_invites.build(invite_params)
    if @invite.save
      InviteMailer.invite_email(@invite).deliver_later
      redirect_to root_path, notice: "Invite sent to #{@invite.recipient_email}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @invite.accepted?
      redirect_to contacts_path, notice: "Already accepted"
    else
      @invite.accept!(current_user)
      redirect_to contacts_path, notice: "You are now connected with #{@invite.sender.name}!"
    end
  end

  def destroy
    @invite.destroy!
    redirect_to invites_path, notice: "Invite declined"
  end

  private

  def set_invite
    @invite = Invite.find_by!(token: params[:token])
    authorize_recipient!
  end

  def authorize_recipient!
    raise ActiveRecord::RecordNotFound unless @invite.recipient_email == current_user.email_address
  end

  def current_user
    Current.session.user
  end

  def invite_params
    params.require(:invite).permit(:recipient_email)
  end
end
