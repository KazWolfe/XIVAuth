module DeviceAuthorizationGrantPatches
  # patches the /token endpoint for device codes
  module DeviceCodeRequestPatch
    def grant
      device_grant
    end

    def check_grant_errors!
      super
      check_denial!
    end

    def check_denial!
      return unless device_grant.denied

      device_grant.destroy!
      raise Doorkeeper::Errors::DoorkeeperError.new :access_denied
    end
  end

  def self.apply_patches
    Doorkeeper::DeviceAuthorizationGrant::OAuth::DeviceCodeRequest.prepend(DeviceCodeRequestPatch)
  end
end