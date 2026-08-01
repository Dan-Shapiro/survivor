# A 4-digit PIN is only 10,000 combinations, and there's no self-serve reset
# (see docs/GAME_DESIGN.md#edge-cases) — rate-limiting login attempts is the
# real defense against brute-forcing it.
class Rack::Attack
  throttle("logins/email", limit: 5, period: 1.minute) do |req|
    req.params["email"].to_s.downcase.strip if req.path == "/login" && req.post?
  end

  throttle("logins/ip", limit: 20, period: 1.minute) do |req|
    req.ip if req.path == "/login" && req.post?
  end
end

Rails.application.config.middleware.use Rack::Attack
