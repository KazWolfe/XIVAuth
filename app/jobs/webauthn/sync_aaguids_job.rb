class Webauthn::SyncAaguidsJob < ApplicationJob
  queue_as :cronjobs

  def perform(*)
    Webauthn::DeviceClass.load_from_dataset
  end
end
