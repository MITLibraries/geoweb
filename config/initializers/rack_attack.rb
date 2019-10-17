class Rack::Attack
  # Once we move to Redis, configure as part of Rails and remove this and
  # rack attack with just use the rails cache
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Throttle non asset and non ogc requests by IP (30rpm)
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
  throttle('req/ip', limit: 150, period: 5.minutes) do |req|
    unless req.path.start_with?('/ogc') || req.path.start_with?('/assets')
      req.ip
    end
  end
end
