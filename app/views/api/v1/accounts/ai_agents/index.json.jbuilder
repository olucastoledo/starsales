json.array! @ai_agents do |agent|
  json.partial! 'api/v1/models/ai_agent', formats: [:json], resource: agent
end
