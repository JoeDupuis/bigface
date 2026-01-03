class Call < ApplicationRecord
  belongs_to :caller, class_name: "User"
  belongs_to :recipient, class_name: "User"
  belongs_to :answered_by_session, class_name: "Session", optional: true
end
