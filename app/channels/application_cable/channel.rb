module ApplicationCable
  class Channel < ActionCable::Channel::Base
    delegate :session, :ability, to: :connection
    protected :session, :ability
  end
end
