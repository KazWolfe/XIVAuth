# frozen_string_literal: true

class Admin::DashboardController < Admin::AdminController
  def index
    @status = {
      "Current Users": User.count,
      "Current Character Registrations": CharacterRegistration.count,
      "Current Verified CRs": CharacterRegistration.verified.count,
      "Current Known Characters": FFXIV::Character.count
    }
  end
end
