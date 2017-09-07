Rails.application.configure do
  config.ogcproxy = HashWithIndifferentAccess.new config_for(:ogcproxy)
  config.middleware.insert_after Warden::Manager, OgcProxy, config.ogcproxy
end
