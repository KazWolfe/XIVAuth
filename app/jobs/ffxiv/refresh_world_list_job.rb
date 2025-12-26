class FFXIV::RefreshWorldListJob < ApplicationJob
  queue_as :cronjobs

  def perform(*)
    FFXIV::WorldList.refresh!
  end
end
