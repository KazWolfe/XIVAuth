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
      this.is.thancred@lnkprl.com
      cid@garlondironworks.com
      wanderingminstrel@orchestri.on
      starboard@omega.ai
      larboard@omega.ai
      securingway@carrot.moon
      conjuringcatgirl@aether.net
    ].sample
  end
end
