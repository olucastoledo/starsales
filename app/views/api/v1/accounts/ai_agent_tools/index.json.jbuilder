json.array! @ai_agent_tools do |tool|
  json.partial! 'api/v1/models/ai_agent_tool', formats: [:json], resource: tool
end
