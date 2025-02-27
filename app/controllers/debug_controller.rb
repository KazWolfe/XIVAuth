class DebugController < Admin::AdminController
  include DynamicActionRouting

  def generate_exception
    raise "The exception you asked for."
  end
end
