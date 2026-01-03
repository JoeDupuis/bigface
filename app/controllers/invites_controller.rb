class InvitesController < ApplicationController
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

  private

  def invite_params
    params.require(:invite).permit(:recipient_email)
  end
end
