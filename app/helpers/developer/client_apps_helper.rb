module Developer::ClientAppsHelper
  def app_submit_path(application)
    application.persisted? ? developer_application_path(application) : developer_applications_path
  end
end
