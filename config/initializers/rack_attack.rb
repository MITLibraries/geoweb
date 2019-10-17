class Rack::Attack
  # Once we move to Redis, configure as part of Rails and remove this and
  # rack attack with just use the rails cache
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  THROTTLE_TIME = ENV.fetch("THROTTLE_TIME", 5).to_i
  THROTTLE_COUNT = ENV.fetch("THROTTLE_COUNT", 150).to_i

  # Throttle non asset and non ogc requests by IP (30rpm)
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
  throttle('req/ip', limit: THROTTLE_COUNT, period: THROTTLE_TIME.minutes) do |req|
    unless req.path.start_with?('/ogc') || req.path.start_with?('/assets')
      req.ip
    end
  end

  Rack::Attack.throttled_response = lambda do |env|
    [ 429, {}, ["The site is experiencing heavy usage now. Please try your request again in a few minutes.\n"]]
  end

  # Log when throttles are triggered
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |name, start, finish, request_id, payload|
    @@rack_logger ||= ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
    @@rack_logger.info{[
      "[#{payload[:request].env['rack.attack.match_type']}]",
      "[#{payload[:request].env['rack.attack.matched']}]",
      "[#{payload[:request].env['rack.attack.match_discriminator']}]",
      "[#{payload[:request].env['rack.attack.throttle_data']}]",
      ].join(' ') }
  end
end
