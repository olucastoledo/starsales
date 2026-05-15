json.id resource.id
json.account_id resource.account_id
json.name resource.name
json.description resource.description
json.personality resource.personality
json.system_prompt resource.system_prompt
json.temperature resource.temperature
json.model resource.model
json.enabled resource.enabled
json.debounce_delay_seconds resource.debounce_delay_seconds
json.context_window_messages resource.context_window_messages
json.custom_attributes resource.custom_attributes
json.tools resource.ai_agent_tools.enabled.map do |tool|
  json.id tool.id
  json.name tool.name
  json.description tool.description
  json.tool_type tool.tool_type
  json.enabled tool.enabled
end
json.created_at resource.created_at
json.updated_at resource.updated_at
