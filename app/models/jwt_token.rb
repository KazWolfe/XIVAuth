# frozen_string_literal: true

class JwtToken
  include ActiveModel::API

  attr_accessor :jti,

  def initialize(attributes = {})
    super(attributes)

    this.id ||= SecureRandom.urlsafe_base64(24, padding: false)
  end

  def as_token

  end
end
