class ContactsController < ApplicationController
  def index
    @contacts = Current.session.user.contacts
  end

  def destroy
    @contact = Current.session.user.contacts.find_by(id: params[:id])

    if @contact.nil?
      head :not_found
      return
    end

    Contact.transaction do
      Contact.where(user: @contact.user, contact: @contact.contact).destroy_all
      Contact.where(user: @contact.contact, contact: @contact.user).destroy_all
    end

    redirect_to contacts_path, notice: "Contact removed"
  end
end
