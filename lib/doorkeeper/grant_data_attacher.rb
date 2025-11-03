class Doorkeeper::GrantDataAttacher
  def self.attach(request, response)
    unless response.is_a?(Doorkeeper::OAuth::TokenResponse)
      return
    end

    if request.is_a?(Doorkeeper::OAuth::RefreshTokenRequest)
      grant_flow = Doorkeeper::OAuth::REFRESH_TOKEN
    elsif request.respond_to?(:grant_type)
      grant_flow = request.grant_type
    else
      grant_flow = nil
    end

    response.token.source_grant_flow = grant_flow
    response.token.save
  end
end
