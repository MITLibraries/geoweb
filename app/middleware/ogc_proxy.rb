require 'base64'
require 'rack/proxy'

class OgcProxy < Rack::Proxy

  def perform_request(env)
    request = Rack::Request.new(env)
    if %r{^/ogc/(?<service>wms|wfs)$} =~ request.path
      prefix = (Rails.configuration.ogcproxy[:prefix] || '').gsub(/\/+$/, '')
      username = Rails.configuration.ogcproxy[:username]
      password = Rails.configuration.ogcproxy[:password]
      env['QUERY_STRING'] = request.query_string
      env['PATH_INFO'] = "#{prefix}/#{service}"
      if env['warden'].authenticated?
        auth = Base64::strict_encode64("#{username}:#{password}")
        env['HTTP_AUTHORIZATION'] =  "Basic #{auth}"
      end
      super(env)
    else
      @app.call(env)
    end
  end
end
