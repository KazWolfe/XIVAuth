module Portal::Developer::ClientApplicationHelper
  def app_deletable(app)
    !app.verified?
  end
end
