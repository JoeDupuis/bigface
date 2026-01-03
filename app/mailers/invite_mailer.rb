class InviteMailer < ApplicationMailer
  def invite_email(invite)
    @invite = invite
    @sender = invite.sender
    @accept_url = invite_url(invite.token)

    mail(
      to: invite.recipient_email,
      subject: "#{@sender.name} has invited you to BigFace"
    )
  end
end
