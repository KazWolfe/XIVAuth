module DynamicActionRouting
  def dynamic_action
    unless respond_to?(params[:dynamic_action])
      raise ActionController::RoutingError, "action #{params[:dynamic_action].inspect} not found"
    end

    self.action_name = params[:dynamic_action]
    public_send(params[:dynamic_action])
  end
end
