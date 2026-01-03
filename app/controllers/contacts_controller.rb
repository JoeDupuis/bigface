class ContactsController < ApplicationController
  def index
    @contacts = Current.session.user.contacts
  end
end
