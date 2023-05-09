# frozen_string_literal: true

module Users::SessionsHelper
  def eegg_random_npc_email
    %w[
      raubahn@syndicate.uldah.gov
      mbloefhiswyn@lanoscea.gov
      kan.e.senna@gridania.gov
      zenos@royal.garlemald.mil
      fleveilleur@sharlayan.edu
      warrioroflight@eorzeamail.com
      godbert@goldsaucer.net
      tataru@seventhdawn.org
    ].sample
  end
end
