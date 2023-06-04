# frozen_string_literal: true

class Api::V1::JwtVerificationController < Api::V1::ApiController
  def verify
    render json: {
      valid: false
    }
  end
end
