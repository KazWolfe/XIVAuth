class DebugController < ApplicationController
  def generate_exception
    raise "The exception you asked for."
  end
end
